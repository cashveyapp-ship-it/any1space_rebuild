const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const Stripe = require("stripe");

admin.initializeApp();

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

exports.createBookingPaymentIntent = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const {
      bookingId,
      hostId,
      amount,
      currency,
      connectedAccountId,
    } = request.data;

    if (!bookingId || !hostId || !amount) {
      throw new HttpsError("invalid-argument", "Missing payment data.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    const amountInCents = Math.round(Number(amount) * 100);
    const platformFee = Math.round(amountInCents * 0.20);

    const paymentIntentParams = {
      amount: amountInCents,
      currency: currency || "usd",
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        bookingId,
        hostId,
        driverId: request.auth.uid,
        platform: "Any1Space",
      },
      application_fee_amount: platformFee,
    };

    const requestOptions = connectedAccountId
      ? { stripeAccount: connectedAccountId }
      : undefined;

    const paymentIntent = await stripe.paymentIntents.create(
      paymentIntentParams,
      requestOptions
    );

    await admin.firestore().collection("payments").doc(paymentIntent.id).set({
      id: paymentIntent.id,
      bookingId,
      driverId: request.auth.uid,
      hostId,
      grossAmount: Number(amount),
      platformFee: platformFee / 100,
      hostPayout: Number(amount) - platformFee / 100,
      stripePaymentIntentId: paymentIntent.id,
      connectedAccountId: connectedAccountId || null,
      status: "created",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      platformFee: platformFee / 100,
    };
  }
);

exports.markBookingPaidAfterPayment = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { bookingId, paymentIntentId } = request.data;

    if (!bookingId || !paymentIntentId) {
      throw new HttpsError("invalid-argument", "Missing booking/payment data.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== "succeeded") {
      throw new HttpsError("failed-precondition", "Payment has not succeeded.");
    }

    const bookingRef = admin.firestore().collection("bookings").doc(bookingId);

    await admin.firestore().runTransaction(async (tx) => {
      const bookingSnap = await tx.get(bookingRef);

      if (!bookingSnap.exists) {
        throw new HttpsError("not-found", "Booking not found.");
      }

      const booking = bookingSnap.data();
      const spaceRef = admin.firestore().collection("spaces").doc(booking.spaceId);

      tx.update(bookingRef, {
        status: "paid",
        paymentStatus: "paid",
        paymentId: paymentIntentId,
        qrCode: `ANY1SPACE-${bookingId}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(spaceRef, {
        availableSpaces: admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(
        admin.firestore().collection("payments").doc(paymentIntentId),
        {
          status: "paid",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return {
      success: true,
      qrCode: `ANY1SPACE-${bookingId}`,
    };
  }
);

exports.createStripeConnectAccount = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const uid = request.auth.uid;
    const email = request.auth.token.email || request.data.email || "";

    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    let connectedAccountId = userSnap.exists
      ? userSnap.data().stripeConnectedAccountId
      : null;

    if (!connectedAccountId) {
      const account = await stripe.accounts.create({
        type: "express",
        email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        metadata: {
          uid,
          platform: "Any1Space",
        },
      });

      connectedAccountId = account.id;

      await userRef.set(
        {
          stripeConnectedAccountId: connectedAccountId,
          stripeOnboardingComplete: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    const refreshUrl =
      request.data.refreshUrl || "https://www.any1space.com/stripe-refresh";
    const returnUrl =
      request.data.returnUrl || "https://www.any1space.com/stripe-return";

    const accountLink = await stripe.accountLinks.create({
      account: connectedAccountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: "account_onboarding",
    });

    return {
      connectedAccountId,
      url: accountLink.url,
    };
  }
);

exports.refreshStripeConnectAccountStatus = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    if (!userSnap.exists || !userSnap.data().stripeConnectedAccountId) {
      throw new HttpsError("failed-precondition", "No Stripe account found.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const connectedAccountId = userSnap.data().stripeConnectedAccountId;
    const account = await stripe.accounts.retrieve(connectedAccountId);

    const onboardingComplete =
      account.details_submitted &&
      account.charges_enabled &&
      account.payouts_enabled;

    await userRef.set(
      {
        stripeOnboardingComplete: onboardingComplete,
        stripeChargesEnabled: account.charges_enabled,
        stripePayoutsEnabled: account.payouts_enabled,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      connectedAccountId,
      onboardingComplete,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
    };
  }
);

async function sendPushToUser(uid, title, body, data = {}) {
  const userSnap = await admin.firestore().collection("users").doc(uid).get();

  if (!userSnap.exists) {
    return false;
  }

  const token = userSnap.data().fcmToken;

  if (!token) {
    return false;
  }

  await admin.messaging().send({
    token,
    notification: {
      title,
      body,
    },
    data,
  });

  return true;
}

exports.notifyBookingPaid = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { bookingId } = request.data;

    if (!bookingId) {
      throw new HttpsError("invalid-argument", "Missing bookingId.");
    }

    const bookingSnap = await admin
      .firestore()
      .collection("bookings")
      .doc(bookingId)
      .get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingSnap.data();

    await sendPushToUser(
      booking.driverId,
      "Booking Confirmed",
      "Your Any1Space booking is paid and your QR pass is ready.",
      {
        bookingId,
        type: "booking_paid",
      }
    );

    await sendPushToUser(
      booking.hostId,
      "New Paid Booking",
      "A driver booked your space.",
      {
        bookingId,
        type: "host_booking_paid",
      }
    );

    return { success: true };
  }
);

exports.notifyBookingCheckedIn = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { bookingId } = request.data;

    const bookingSnap = await admin
      .firestore()
      .collection("bookings")
      .doc(bookingId)
      .get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingSnap.data();

    await sendPushToUser(
      booking.driverId,
      "Vehicle Checked In",
      "Your vehicle has been checked in by an attendant.",
      {
        bookingId,
        type: "booking_checked_in",
      }
    );

    return { success: true };
  }
);

exports.notifyBookingCheckedOut = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { bookingId } = request.data;

    const bookingSnap = await admin
      .firestore()
      .collection("bookings")
      .doc(bookingId)
      .get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingSnap.data();

    await sendPushToUser(
      booking.driverId,
      "Vehicle Checked Out",
      "Your vehicle has been checked out.",
      {
        bookingId,
        type: "booking_checked_out",
      }
    );

    return { success: true };
  }
);

exports.refundBookingPayment = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const adminEmails = ["alerttmenow@gmail.com", "cashveyapp@gmail.com"];
    const callerEmail = (request.auth.token.email || "").toLowerCase();

    if (!adminEmails.includes(callerEmail)) {
      throw new HttpsError("permission-denied", "Admin only.");
    }

    const { bookingId, amount, reason } = request.data;

    if (!bookingId) {
      throw new HttpsError("invalid-argument", "Missing bookingId.");
    }

    const bookingRef = admin.firestore().collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingSnap.data();

    if (!booking.paymentIntentId) {
      throw new HttpsError("failed-precondition", "Booking has no paymentIntentId.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    const refundPayload = {
      payment_intent: booking.paymentIntentId,
      metadata: {
        bookingId,
        reason: reason || "admin_refund",
      },
    };

    if (amount && amount > 0) {
      refundPayload.amount = Math.round(amount * 100);
    }

    const refund = await stripe.refunds.create(refundPayload);

    await bookingRef.set(
      {
        refundStatus: refund.status,
        refundId: refund.id,
        refundReason: reason || "Admin refund",
        refundedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "refunded",
        paymentStatus: "refunded",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await admin.firestore().collection("refunds").doc(refund.id).set({
      id: refund.id,
      bookingId,
      paymentIntentId: booking.paymentIntentId,
      amount: amount || booking.amount || 0,
      status: refund.status,
      reason: reason || "Admin refund",
      driverId: booking.driverId || "",
      hostId: booking.hostId || "",
      createdBy: request.auth.uid,
      createdByEmail: callerEmail,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (booking.driverId) {
      const notificationRef = admin
        .firestore()
        .collection("users")
        .doc(booking.driverId)
        .collection("notifications")
        .doc();

      await notificationRef.set({
        id: notificationRef.id,
        title: "Refund Processed",
        body: "A refund has been processed for your Any1Space booking.",
        type: "refund_processed",
        data: { bookingId, refundId: refund.id },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      refundId: refund.id,
      status: refund.status,
    };
  }
);

exports.sendBookingReminder = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const { bookingId, reminderType } = request.data;

    if (!bookingId) {
      throw new HttpsError("invalid-argument", "Missing bookingId.");
    }

    const bookingSnap = await admin
      .firestore()
      .collection("bookings")
      .doc(bookingId)
      .get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingSnap.data();

    let title = "Booking Reminder";
    let body = "You have an Any1Space booking reminder.";

    if (reminderType === "starts_soon") {
      title = "Booking Starts Soon";
      body = "Your parking booking starts soon. Please arrive on time.";
    }

    if (reminderType === "ending_soon") {
      title = "Booking Ending Soon";
      body = "Your parking booking is ending soon. Please move or extend if needed.";
    }

    const userId = booking.driverId;

    if (!userId) {
      throw new HttpsError("failed-precondition", "Booking has no driver.");
    }

    const notificationRef = admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .doc();

    await notificationRef.set({
      id: notificationRef.id,
      title,
      body,
      type: reminderType || "booking_reminder",
      data: { bookingId },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

exports.createHostConnectOnboardingLink = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const email = request.auth.token.email || "";

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    let stripeAccountId = userSnap.exists ? userSnap.data().stripeAccountId : null;

    if (!stripeAccountId) {
      const account = await stripe.accounts.create({
        type: "express",
        email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        metadata: {
          uid,
          platform: "Any1Space",
        },
      });

      stripeAccountId = account.id;

      await userRef.set(
        {
          stripeAccountId,
          stripeConnectStatus: "created",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,
      refresh_url: "https://www.any1space.com/stripe-refresh",
      return_url: "https://www.any1space.com/stripe-return",
      type: "account_onboarding",
    });

    return {
      url: accountLink.url,
      stripeAccountId,
    };
  }
);

exports.checkHostConnectStatus = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    if (!userSnap.exists || !userSnap.data().stripeAccountId) {
      return {
        connected: false,
        status: "not_started",
      };
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const stripeAccountId = userSnap.data().stripeAccountId;
    const account = await stripe.accounts.retrieve(stripeAccountId);

    const connected =
      account.details_submitted === true &&
      account.charges_enabled === true &&
      account.payouts_enabled === true;

    await userRef.set(
      {
        stripeConnectStatus: connected ? "connected" : "pending",
        stripeChargesEnabled: account.charges_enabled,
        stripePayoutsEnabled: account.payouts_enabled,
        stripeDetailsSubmitted: account.details_submitted,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      connected,
      status: connected ? "connected" : "pending",
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      detailsSubmitted: account.details_submitted,
    };
  }
);

async function resolveCallableUserV2(request) {
  if (request.auth && request.auth.uid) {
    return {
      uid: request.auth.uid,
      email: request.auth.token.email || "",
    };
  }

  const idToken = request.data && request.data.idToken;
  if (!idToken) {
    throw new HttpsError("unauthenticated", "Missing Firebase auth token.");
  }

  const decoded = await admin.auth().verifyIdToken(idToken);
  return {
    uid: decoded.uid,
    email: decoded.email || "",
  };
}

exports.createBookingPaymentIntentV2 = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    const caller = await resolveCallableUserV2(request);

    const { bookingId, hostId, amount } = request.data;

    if (!bookingId || !hostId || !amount || amount <= 0) {
      throw new HttpsError("invalid-argument", "Missing bookingId, hostId, or amount.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    const amountCents = Math.round(Number(amount) * 100);
    const platformFeePercent = 20;
    const platformFeeCents = Math.round(amountCents * 0.20);
    const hostNetCents = amountCents - platformFeeCents;

    const hostSnap = await admin.firestore().collection("users").doc(hostId).get();
    const host = hostSnap.exists ? hostSnap.data() : {};
    const stripeAccountId = host.stripeAccountId || null;
    const connectReady =
      stripeAccountId &&
      host.stripeConnectStatus === "connected" &&
      host.stripeChargesEnabled === true &&
      host.stripePayoutsEnabled === true;

    const paymentIntentParams = {
      amount: amountCents,
      currency: "usd",
      automatic_payment_methods: { enabled: true },
      metadata: {
        bookingId,
        hostId,
        driverId: caller.uid,
        platformFeePercent: String(platformFeePercent),
        platformFeeCents: String(platformFeeCents),
        hostNetCents: String(hostNetCents),
      },
    };

    if (connectReady) {
      paymentIntentParams.application_fee_amount = platformFeeCents;
      paymentIntentParams.transfer_data = {
        destination: stripeAccountId,
      };
    }

    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);

    await admin.firestore().collection("bookings").doc(bookingId).set(
      {
        driverId: caller.uid,
        hostId,
        paymentIntentId: paymentIntent.id,
        paymentStatus: "requires_payment",
        platformFeePercent,
        platformFee: platformFeeCents / 100,
        hostNet: hostNetCents / 100,
        stripeDestinationAccountId: connectReady ? stripeAccountId : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await admin.firestore().collection("payments").doc(paymentIntent.id).set({
      id: paymentIntent.id,
      bookingId,
      hostId,
      driverId: caller.uid,
      amount: Number(amount),
      amountCents,
      platformFeePercent,
      platformFee: platformFeeCents / 100,
      platformFeeCents,
      hostNet: hostNetCents / 100,
      hostNetCents,
      stripeAccountId: connectReady ? stripeAccountId : null,
      status: "requires_payment",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      platformFee: platformFeeCents / 100,
      hostNet: hostNetCents / 100,
    };
  }
);

exports.markBookingPaidAfterPaymentV2 = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    const caller = await resolveCallableUserV2(request);

    const { bookingId, paymentIntentId } = request.data;

    if (!bookingId || !paymentIntentId) {
      throw new HttpsError("invalid-argument", "Missing bookingId or paymentIntentId.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== "succeeded") {
      throw new HttpsError("failed-precondition", "Payment has not succeeded.");
    }

    const bookingRef = admin.firestore().collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }

    const booking = bookingSnap.data();
    const amount = (paymentIntent.amount || 0) / 100;
    const platformFee = booking.platformFee || amount * 0.20;
    const hostNet = booking.hostNet || amount - platformFee;

    await bookingRef.set(
      {
        status: "paid",
        paymentStatus: "paid",
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await admin.firestore().collection("payments").doc(paymentIntentId).set(
      {
        status: "paid",
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await admin.firestore().collection("hostEarnings").doc().set({
      bookingId,
      paymentIntentId,
      hostId: booking.hostId,
      driverId: booking.driverId || caller.uid,
      spaceId: booking.spaceId,
      spaceName: booking.spaceName,
      grossAmount: amount,
      platformFee,
      hostNet,
      status: "earned",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      grossAmount: amount,
      platformFee,
      hostNet,
    };
  }
);

exports.expireOldBookings = onSchedule(
  {
    schedule: "every 15 minutes",
    region: "us-central1",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const snap = await admin
      .firestore()
      .collection("bookings")
      .where("status", "in", ["paid", "reserved", "confirmed"])
      .where("endTime", "<", now)
      .get();

    if (snap.empty) {
      console.log("No expired bookings found.");
      return;
    }

    const batch = admin.firestore().batch();

    snap.docs.forEach((doc) => {
      const booking = doc.data();

      batch.set(
        doc.ref,
        {
          status: "expired",
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      if (booking.spaceId) {
        batch.set(
          admin.firestore().collection("spaces").doc(booking.spaceId),
          {
            availableSpaces: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    });

    await batch.commit();

    console.log(`Expired ${snap.size} booking(s).`);
  }
);

exports.createAttendantShiftPaymentIntent = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    const { shiftId } = request.data;

    if (!shiftId) {
      throw new HttpsError("invalid-argument", "Missing shiftId.");
    }

    const shiftRef = admin.firestore().collection("attendantShifts").doc(shiftId);
    const shiftSnap = await shiftRef.get();

    if (!shiftSnap.exists) {
      throw new HttpsError("not-found", "Shift not found.");
    }

    const shift = shiftSnap.data();
    const attendantId = shift.attendantId;
    const hostId = shift.hostId;
    const amount = Number(shift.estimatedPay || 0);

    if (!attendantId || !hostId || amount <= 0) {
      throw new HttpsError("failed-precondition", "Shift is missing attendant, host, or pay amount.");
    }

    const attendantSnap = await admin.firestore().collection("users").doc(attendantId).get();
    const attendant = attendantSnap.exists ? attendantSnap.data() : {};
    const stripeAccountId = attendant.attendantStripeAccountId || attendant.stripeAccountId || null;

    const ready =
      stripeAccountId &&
      (attendant.attendantStripePayoutsEnabled === true || attendant.stripePayoutsEnabled === true);

    if (!ready) {
      throw new HttpsError("failed-precondition", "Attendant payout setup is not complete.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());

    const serviceFee = amount * 0.03;
    const totalCharged = amount + serviceFee;

    const amountCents = Math.round(totalCharged * 100);
    const serviceFeeCents = Math.round(serviceFee * 100);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: "usd",
      automatic_payment_methods: { enabled: true },
      application_fee_amount: serviceFeeCents,
      transfer_data: {
        destination: stripeAccountId,
      },
      metadata: {
        shiftId,
        hostId,
        attendantId,
        attendantPay: amount.toFixed(2),
        serviceFee: serviceFee.toFixed(2),
        totalCharged: totalCharged.toFixed(2),
        paymentType: "attendant_shift_payment",
      },
    });

    await admin.firestore().collection("attendantPayments").doc(paymentIntent.id).set({
      id: paymentIntent.id,
      shiftId,
      hostId,
      attendantId,
      attendantPay: amount,
      serviceFee,
      totalCharged,
      serviceFeePercent: 3,
      paymentIntentId: paymentIntent.id,
      status: "requires_payment",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await shiftRef.set({
      paymentStatus: "requiresAppPayment",
      paymentIntentId: paymentIntent.id,
      serviceFee,
      totalCharged,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      attendantPay: amount,
      serviceFee,
      totalCharged,
    };
  }
);

exports.markAttendantShiftPaidAfterPayment = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    const { shiftId, paymentIntentId } = request.data;

    if (!shiftId || !paymentIntentId) {
      throw new HttpsError("invalid-argument", "Missing shiftId or paymentIntentId.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== "succeeded") {
      throw new HttpsError("failed-precondition", "Payment has not succeeded.");
    }

    await admin.firestore().collection("attendantShifts").doc(shiftId).set({
      paymentStatus: "paidInApp",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await admin.firestore().collection("attendantPayments").doc(paymentIntentId).set({
      status: "paid",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true };
  }
);



exports.createAttendantConnectAccount = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const uid = request.auth.uid;
    const email = request.auth.token.email || "";

    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    let stripeAccountId = userSnap.exists ? userSnap.data().attendantStripeAccountId : null;

    if (!stripeAccountId) {
      const account = await stripe.accounts.create({
        type: "express",
        email,
        capabilities: {
          transfers: { requested: true },
        },
      });

      stripeAccountId = account.id;

      await userRef.set({
        attendantStripeAccountId: stripeAccountId,
        attendantStripeConnectStatus: "created",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    return { accountId: stripeAccountId };
  }
);

exports.createAttendantConnectOnboardingLink = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const uid = request.auth.uid;

    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    let stripeAccountId = userSnap.exists ? userSnap.data().attendantStripeAccountId : null;

    if (!stripeAccountId) {
      const account = await stripe.accounts.create({
        type: "express",
        email: request.auth.token.email || "",
        capabilities: {
          transfers: { requested: true },
        },
      });

      stripeAccountId = account.id;

      await userRef.set({
        attendantStripeAccountId: stripeAccountId,
        attendantStripeConnectStatus: "created",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,
      refresh_url: "https://www.an2app.com",
      return_url: "https://www.an2app.com",
      type: "account_onboarding",
    });

    return { url: accountLink.url };
  }
);

exports.checkAttendantConnectStatus = onCall(
  {
    region: "us-central1",
    secrets: [STRIPE_SECRET_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in.");
    }

    const uid = request.auth.uid;
    const userRef = admin.firestore().collection("users").doc(uid);
    const userSnap = await userRef.get();

    if (!userSnap.exists || !userSnap.data().attendantStripeAccountId) {
      return {
        connected: false,
        chargesEnabled: false,
        payoutsEnabled: false,
        status: "not_started",
      };
    }

    const stripe = new Stripe(STRIPE_SECRET_KEY.value());
    const stripeAccountId = userSnap.data().attendantStripeAccountId;
    const account = await stripe.accounts.retrieve(stripeAccountId);

    await userRef.set({
      attendantStripeChargesEnabled: account.charges_enabled,
      attendantStripePayoutsEnabled: account.payouts_enabled,
      attendantStripeConnectStatus:
        account.charges_enabled && account.payouts_enabled ? "connected" : "pending",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      connected: account.charges_enabled && account.payouts_enabled,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      status: account.charges_enabled && account.payouts_enabled ? "connected" : "pending",
    };
  }
);




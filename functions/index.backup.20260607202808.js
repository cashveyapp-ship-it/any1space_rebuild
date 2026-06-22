const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
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

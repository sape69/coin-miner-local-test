async function seedReferralGroup(name) {
  const allowedCharacters =
    "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

  const suffix = Array.from(
    { length: 4 },
    () => allowedCharacters[
      Math.floor(Math.random() * allowedCharacters.length)
    ],
  ).join("");

  const code = `STEA${suffix}`;

  const data = createTestCase(name, code);

  const activeUid = `${testPrefix}-${name}-active`;
  const inactiveUid = `${testPrefix}-${name}-inactive`;

  createdUserUids.add(activeUid);
  createdUserUids.add(inactiveUid);

  createdReferralUids.add(activeUid);
  createdReferralUids.add(inactiveUid);

  await seedReferrer(data);

  await db
    .collection("users")
    .doc(data.referrerUid)
    .set({
      referralCount: 2,
      referralTotalEarned: 3.75,
    }, { merge: true });

  await seedReferredUser({
    uid: activeUid,
    referrerUid: data.referrerUid,
    referralCode: data.code,
    active: true,
    bonus: 1.25,
  });

  await seedReferredUser({
    uid: inactiveUid,
    referrerUid: data.referrerUid,
    referralCode: data.code,
    active: false,
    bonus: 2.50,
  });

  return {
    ...data,
    activeUid,
    inactiveUid,
  };
}
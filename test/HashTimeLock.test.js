const HashTimeLock = artifacts.require("HashTimeLock");
const { toWei, soliditySha3 } = web3.utils;

contract("HashTimeLock", (accounts) => {
  const [initiator, participant] = accounts;
  let htlc;
  const secret = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
  const hashlock = soliditySha3(secret);
  const timelock = Math.floor(Date.now() / 1000) + 3600;
  const amount = toWei("1", "ether");

  beforeEach(async () => {
    htlc = await HashTimeLock.new();
  });

  it("should initiate a new swap correctly", async () => {
    const tx = await htlc.initiate(participant, hashlock, timelock, {
      from: initiator,
      value: amount,
    });

    const swapId = tx.logs[0].args.swapId;
    assert.exists(swapId, "Swap ID should exist");

    const swap = await htlc.swaps(swapId);
    assert.equal(swap.initiator, initiator, "Incorrect initiator");
    assert.equal(swap.participant, participant, "Incorrect participant");
    assert.equal(swap.amount.toString(), amount.toString(), "Incorrect amount");
    assert.equal(swap.hashlock, hashlock, "Incorrect hashlock");
    assert.equal(swap.timelock.toString(), timelock.toString(), "Incorrect timelock");
    assert.equal(swap.completed, false, "Swap should not be completed");
    assert.equal(swap.refunded, false, "Swap should not be refunded");
  });
});

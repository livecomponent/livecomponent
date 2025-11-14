import { AsyncTaskQueue } from "./queue";
import { describe, it, expect } from "vitest";

describe("AsyncTaskQueue", () => {
  it("executes tasks in the order they were enqueued", async () => {
    const queue = new AsyncTaskQueue();
    const task_results = [];

    await Promise.all([
      queue.enqueue(() => {
        return new Promise<void>((resolve) => {
          setTimeout(() => {
            task_results.push("foo");
            resolve();
          }, 1000);
        });
      }),

      queue.enqueue(async () => {
        task_results.push("bar");
      }),
    ]);

    // expect "foo" to be first even though it slept for 1s
    expect(task_results).toStrictEqual(["foo", "bar"]);
  });

  it("continually processes tasks", async () => {
    const queue = new AsyncTaskQueue<string>();

    expect(
      await Promise.all([
        queue.enqueue(async () => "foo"),
        queue.enqueue(async () => "bar"),
      ])
    ).toStrictEqual(["foo", "bar"]);

    expect(
      await Promise.all([
        queue.enqueue(async () => "baz"),
        queue.enqueue(async () => "boo"),
      ])
    ).toStrictEqual(["baz", "boo"]);
  });
});

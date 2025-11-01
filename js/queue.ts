export type Task<T> = () => Promise<T>;

export class AsyncTaskQueue<T> {
  private q: Array<{
    run: Task<T>;
    resolve: (value: T) => void;
    reject: (reason?: unknown) => void;
  }> = [];

  private running = false;

  enqueue(task: () => Promise<T>): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      this.q.push({
        run: task,
        resolve,
        reject,
      });

      if (!this.running) this.drain();
    });
  }

  private async drain(): Promise<void> {
    this.running = true;

    while (this.q.length) {
      const { run, resolve, reject } = this.q.shift()!;

      try {
        const value = await run();
        resolve(value);
      } catch (err) {
        console.log(err);
        reject(err);
      }
    }

    this.running = false;
  }
}

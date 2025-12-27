export type TaskFn<T> = (task?: Task<T>) => Promise<T>;

export class Task<T> {
  public result: Promise<T>;
  public canceled: boolean;
  public options: TaskOptions;

  constructor(options: TaskOptions) {
    this.options = options;
    this.canceled = false;
  }

  cancel() {
    this.canceled = true;
  }

  then(...args: Parameters<Promise<T>["then"]>): ReturnType<Promise<T>["then"]> {
    return this.result.then(...args);
  }

  catch(...args: Parameters<Promise<T>["catch"]>): ReturnType<Promise<T>["catch"]> {
    return this.result.catch(...args);
  }
}

export type TaskMode = "immediate" | "preempt";

export type TaskOptions = {
  mode: TaskMode;
}

export class AsyncTaskQueue<T> {
  private q: Array<{
    run: TaskFn<T>;
    task: Task<T>;
    resolve: (value: T) => void;
    reject: (reason?: unknown) => void;
  }> = [];

  private running = false;
  private current_task: Task<any> | null = null;

  enqueue(task_fn: TaskFn<T>, options: TaskOptions = { mode: "immediate" }): Task<T> {
    if (options.mode === "preempt") {
      this.current_task?.cancel();
      this.q.splice(0);
    }

    const task = new Task<T>(options);

    task.result = new Promise<T>((resolve, reject) => {
      this.q.push({
        run: task_fn,
        task,
        resolve,
        reject,
      });

      if (!this.running) this.drain();
    });

    return task;
  }

  private async drain(): Promise<void> {
    this.running = true;

    while (this.q.length) {
      const { run, task, resolve, reject } = this.q.shift()!;

      this.current_task = task;

      try {
        const value = await run(task);
        resolve(value);
      } catch (err) {
        console.log(err);
        reject(err);
      }
    }

    this.running = false;
  }
}

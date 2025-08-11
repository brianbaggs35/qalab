declare module "@hotwired/stimulus" {
  export class Application {
    static start(): Application;
    debug: boolean;
    register(name: string, controller: any): void;
    load(definitions: any): void;
  }

  export class Controller {
    readonly element: HTMLElement;
    connect(): void;
    disconnect(): void;
  }
}

declare module "@hotwired/stimulus-loading" {
  export function eagerLoadControllersFrom(path: string, application: any): void;
}

declare module "@hotwired/turbo-rails" {
  // Turbo-rails module declarations
}
export interface GreetOptions {
  name: string;
  excited?: boolean;
}

/** Build a short greeting for the given name. */
export function greet(options: GreetOptions): string {
  const suffix = options.excited ? "!" : ".";
  return `Hello, ${options.name}${suffix}`;
}

export function greetAll(names: string[]): string[] {
  return names.map((name) => greet({ name }));
}

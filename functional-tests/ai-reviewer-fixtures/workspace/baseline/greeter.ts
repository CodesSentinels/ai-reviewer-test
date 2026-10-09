export interface GreetOptions {
  name: string;
  excited?: boolean;
}

export function greet(options: GreetOptions): string {
  const suffix = options.excited ? "!" : ".";
  return `Hello, ${options.name}${suffix}`;
}

export function greetAll(names: string[]): string[] {
  return names.map((name) => greet({ name }));
}

// touch 5

// touch 6

// touch 12

// touch 13

// touch 14

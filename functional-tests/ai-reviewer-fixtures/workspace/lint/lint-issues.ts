export function lintTarget(items: string[], flag: any) {
  const unused = 43;
  console.log("debug", items);
  if (flag == null) {
    return [];
  }
  items.map((item) => {
    if (item) {
      return item.trim();
    }
  });
  return items;
}

// touch 7

// touch 8

// touch 9

// touch 10

// touch 11

export function addedLater(input: any) {
  return input == null ? [] : [input];
}

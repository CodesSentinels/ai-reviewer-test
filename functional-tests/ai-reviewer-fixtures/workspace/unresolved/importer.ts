import { ghost } from "./does-not-exist";
import phantom from "~/functional-tests/ai-reviewer-fixtures/workspace/missing/phantom";

export function useMissing(): unknown {
  return [ghost, phantom];
}

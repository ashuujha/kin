// Only the completed answer is a draft. Reasoning and truncated replies are not.
export function googleAnswer(value: unknown): string {
  const candidate = (value as {candidates?: Array<{finishReason?: string; content?: {parts?: Array<{text?: unknown; thought?: boolean}>}}>})?.candidates?.[0];
  if (candidate?.finishReason !== "STOP" || !Array.isArray(candidate.content?.parts)) throw new Error("Incomplete answer");
  const answer = candidate.content.parts
    .filter(part => part.thought !== true && typeof part.text === "string")
    .map(part => part.text as string).join("");
  if (!answer.trim()) throw new Error("Empty answer");
  return answer;
}

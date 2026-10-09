export type DraftMedication = {
  name: string; dosage: string | null; frequency: string | null;
  duration: string | null; source_excerpt: string | null;
};
export type Draft = {prescription_date: string | null; clinic: string | null; medications: DraftMedication[]};

function text(value: unknown, max: number, required = false): string | null {
  if (value === null || value === undefined || value === "") {
    if (required) throw new Error("Required field missing");
    return null;
  }
  if (typeof value !== "string" || value.length > max || (required && !value.trim())) throw new Error("Invalid field");
  return value.trim();
}
export function parseDraft(raw: string): Draft {
  if (raw.length > 24000) throw new Error("Output too large");
  const value = JSON.parse(raw.replace(/^\s*```(?:json)?\s*/i, "").replace(/\s*```\s*$/, ""));
  if (!value || typeof value !== "object" || !Array.isArray(value.medications) || value.medications.length > 30) throw new Error("Invalid draft");
  const date = text(value.prescription_date, 10);
  if (date && (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0,10) !== date)) throw new Error("Invalid date");
  return {
    prescription_date: date, clinic: text(value.clinic, 200),
    medications: value.medications.map((m: Record<string, unknown>) => {
      if (!m || typeof m !== "object") throw new Error("Invalid medication");
      return {name: text(m.name,120,true)!, dosage: text(m.dosage,200), frequency: text(m.frequency,200),
        duration: text(m.duration,200), source_excerpt: text(m.source_excerpt,500)};
    }),
  };
}
export function imageMime(bytes: Uint8Array): string | null {
  if (bytes.length < 8 || bytes.length > 5242880) return null;
  if ([137,80,78,71,13,10,26,10].every((v,i)=>bytes[i]===v)) return "image/png";
  if (bytes[0]===255 && bytes[1]===216 && bytes[2]===255) return "image/jpeg";
  return null;
}

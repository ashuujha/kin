export function element<K extends keyof HTMLElementTagNameMap>(tag: K, text?: string, className?: string): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  if (className) node.className = className;
  return node;
}
export function button(text: string, action: () => void | Promise<void>, secondary = false): HTMLButtonElement {
  const node = element('button', text, secondary ? 'button secondary' : 'button');
  node.type = 'button';
  node.addEventListener('click', () => { void action(); });
  return node;
}
export function card(title: string): HTMLElement {
  const node = element('section', undefined, 'card'); node.append(element('h2', title)); return node;
}
export function field(label: string, text: string | null | undefined): HTMLElement {
  const node = element('div', undefined, 'field');
  node.append(element('span', label, 'label'), element('span', text || 'Not recorded', 'value'));
  return node;
}
export function formatTime(iso: string): string {
  const date = new Date(iso); return Number.isFinite(date.getTime()) ? date.toLocaleString() : 'Not recorded';
}
export function safePhone(value: string): string | null {
  return /^\+?[0-9 ()-]{5,25}$/.test(value) ? value.replace(/[ ()-]/g, '') : null;
}

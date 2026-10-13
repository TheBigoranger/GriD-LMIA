import type { ReactNode } from "react";
import { terminologyTerms } from "../data/documentation-contracts.js";

const terms = terminologyTerms
  .filter((term) => term.auto_link)
  .sort((left, right) => right.abbreviation.length - left.abbreviation.length);
const expression = new RegExp(`\\b(${terms.map((term) => term.abbreviation.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|")})\\b`, "g");
const byAbbreviation = new Map(terms.map((term) => [term.abbreviation, term]));

export function TermText({ children }: { children: string }): ReactNode {
  const parts: ReactNode[] = [];
  let cursor = 0;
  for (const match of children.matchAll(expression)) {
    if (match.index > cursor) parts.push(children.slice(cursor, match.index));
    const term = byAbbreviation.get(match[0]);
    parts.push(<a className="term-link" data-term={term.id} href={`/GriD-LMIA${term.web_definition_anchor}`} title={term.expansion} key={`${term.id}-${match.index}`}>{match[0]}</a>);
    cursor = match.index + match[0].length;
  }
  if (cursor < children.length) parts.push(children.slice(cursor));
  return parts;
}

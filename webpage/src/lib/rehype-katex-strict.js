/** Promote renderer parse messages to fatal build errors before fallback markup is serialized. */
export default function rehypeKatexStrict() {
  return (_tree, file) => {
    const parseError = file.messages.find(
      (message) => message.source === "rehype-katex" && message.ruleId === "parseerror",
    );
    if (parseError) throw parseError.cause ?? parseError;
  };
}

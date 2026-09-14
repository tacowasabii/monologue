/** 앱의 lib/domain/dialogue.dart parseDialogue를 옮긴 것. 규칙을 바꾸면 양쪽을 함께 바꾼다. */
export interface DialogueLine {
  speaker: string | null;
  text: string;
  direction: boolean;
}

// 이름은 1~12자, 콜론은 반각·전각 모두
const speakerLine = /^([^:：]{1,12}?)\s*[:：]\s*(.*)$/;
const digitsOnly = /^\d+$/;

function splitSpeaker(line: string): [string, string] | null {
  const m = speakerLine.exec(line);
  if (!m) return null;
  const name = m[1].trim();
  if (name === '' || digitsOnly.test(name) || name.toLowerCase().startsWith('http')) return null;
  return [name, m[2].trim()];
}

export function parseDialogue(body: string): DialogueLine[] {
  const out: DialogueLine[] = [];
  let current: string | null = null;
  let joinable = false;

  const appendToLast = (line: string) => {
    const last = out[out.length - 1];
    last.text = last.text === '' ? line : `${last.text}\n${line}`;
  };

  for (const raw of body.split('\n')) {
    const line = raw.trim();
    if (line === '') {
      current = null;
      joinable = false;
      continue;
    }
    if (line.startsWith('(') && line.endsWith(')')) {
      out.push({ speaker: null, text: line, direction: true });
      joinable = false;
      continue;
    }
    const split = splitSpeaker(line);
    if (split) {
      current = split[0];
      out.push({ speaker: split[0], text: split[1], direction: false });
    } else if (joinable) {
      appendToLast(line);
    } else if (current !== null) {
      out.push({ speaker: current, text: line, direction: false });
    } else {
      out.push({ speaker: null, text: line, direction: true });
    }
    joinable = true;
  }
  return out;
}

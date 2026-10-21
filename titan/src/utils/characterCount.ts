// The API counts Unicode code points (Postgres `char_length`), not UTF-16
// units, so an emoji is 1 here where `text.length` would say 2.
export const countCharacters = (text: string) => [...text].length

export const COMMENT_MAX_LENGTH = 5000

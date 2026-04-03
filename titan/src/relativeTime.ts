export function relativeTime(timeStamp: Date): string {
  //time constants
  const second = 1;
  const minute = second * 60;
  const hour = minute * 60;
  const day = hour * 24;
  const month = day * 30;
  const year = day * 365;

  const timePassed = (Date.now() - timeStamp.getTime()) / 1000;
  if (timePassed < minute) {
    const interval = Math.floor(timePassed) < 0 ? 0 : Math.floor(timePassed);
    return interval == 1 ? "1 second ago" : `${interval} seconds ago`;
  } else if (timePassed < hour) {
    const interval = Math.floor(timePassed / minute);
    return interval == 1 ? "1 minute ago" : `${interval} minutes ago`;
  } else if (timePassed < day) {
    const interval = Math.floor(timePassed / hour);
    return interval == 1 ? "1 hour ago" : `${interval} hours ago`;
  } else if (timePassed < month) {
    const interval = Math.floor(timePassed / day);
    return interval == 1 ? "1 day ago" : `${interval} days ago`;
  } else if (timePassed < year) {
    const interval = Math.floor(timePassed / month);
    return interval == 1 ? "1 month ago" : `${interval} months ago`;
  } else {
    const interval = Math.floor(timePassed / year);
    return interval == 1 ? "1 year ago" : `${interval} years ago`;
  }
}
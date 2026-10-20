/** Convert common share links into embeddable URLs. Returns null if the URL should play in a <video> tag. */
export function embedUrl(url: string): string | null {
  try {
    const u = new URL(url);
    if (u.hostname.includes('youtu.be')) return `https://www.youtube-nocookie.com/embed/${u.pathname.slice(1)}?rel=0&modestbranding=1`;
    if (u.hostname.includes('youtube.com')) {
      const id = u.searchParams.get('v') || u.pathname.split('/').pop();
      return `https://www.youtube-nocookie.com/embed/${id}?rel=0&modestbranding=1`;
    }
    if (u.hostname.includes('vimeo.com') && !u.hostname.startsWith('player.')) return `https://player.vimeo.com/video/${u.pathname.split('/').filter(Boolean)[0]}`;
    if (u.hostname.startsWith('player.') || u.hostname.includes('mediadelivery.net') || u.pathname.includes('/embed')) return url;
    return null;
  } catch { return null; }
}

import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL('https://liuzi-chong.josefina-consequuntu.chatgpt.site'),
  title: '六子冲 · 民间策略棋',
  description: '古朴而精致的六子冲双人策略小游戏。',
  icons: { icon: '/favicon.png' },
  openGraph: {
    title: '六子冲 · 民间策略棋',
    description: '双子成锋，一步制胜。支持多款棋盘、棋子皮肤与原创程序音乐。',
    type: 'website',
    images: [{ url: '/og.png', width: 1731, height: 909, alt: '六子冲民间策略棋' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: '六子冲 · 民间策略棋',
    description: '双子成锋，一步制胜。',
    images: ['/og.png'],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  );
}

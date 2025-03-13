import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Vijil RAG Agent",
  description: "Vijil RAG Agent Interface",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <link rel="icon" href="vijil_icon.ico" />
      <link rel="icon" href="static/vijil_icon.ico" />
      <body>{children}</body>
    </html>
  );
}

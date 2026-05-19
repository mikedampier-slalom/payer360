import type { ReactNode } from "react";

interface ChartCardProps {
  title: string;
  children: ReactNode;
}

export function ChartCard({ title, children }: ChartCardProps) {
  return (
    <div className="rounded-lg border border-gray-800 bg-[#111111] p-4">
      <h3 className="mb-3 text-sm font-semibold text-gray-300">{title}</h3>
      {children}
    </div>
  );
}

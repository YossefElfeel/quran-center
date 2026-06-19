"use client";

import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

// رسم اتجاه شهري عام (مساحة) — للالتحاق وغيره.
export function TrendChart({
  data,
}: {
  data: { month: string; count: number }[];
}) {
  if (data.length === 0) {
    return (
      <p className="py-10 text-center text-sm text-foreground/50">
        لسه مفيش بيانات.
      </p>
    );
  }
  return (
    <ResponsiveContainer width="100%" height={240}>
      <AreaChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e3e3de" />
        <XAxis dataKey="month" tick={{ fontSize: 12 }} />
        <YAxis tick={{ fontSize: 12 }} allowDecimals={false} />
        <Tooltip />
        <Area
          type="monotone"
          dataKey="count"
          stroke="#0C7C59"
          fill="#0C7C5933"
          strokeWidth={2}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

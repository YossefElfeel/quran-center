"use client";

import { formatNumber,formatMonth } from "@/lib/format";
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
        <XAxis dataKey="month" reversed tickFormatter={v=>formatMonth(String(v))} tick={{ fontSize: 12 }} />
        <YAxis orientation="right" tickFormatter={formatNumber} tick={{ fontSize: 12 }} allowDecimals={false} />
        <Tooltip labelFormatter={v=>formatMonth(String(v))} formatter={v=>[formatNumber(Number(v)),"العدد"]} />
        <Area
          type="monotone"
          dataKey="count"
          stroke="var(--color-primary)"
          fill="var(--color-primary)"
          fillOpacity={0.2}
          strokeWidth={2}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

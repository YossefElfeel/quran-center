"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { formatMonth, formatNumber } from "@/lib/format";

export function RevenueChart({
  data,
}: {
  data: { month: string; total: number }[];
}) {
  if (data.length === 0) {
    return (
      <p className="py-10 text-center text-sm text-foreground/50">
        لسه مفيش دفعات مسجّلة.
      </p>
    );
  }
  return (
    <ResponsiveContainer width="100%" height={280}>
      <BarChart data={data} margin={{ top: 8, right: 8, left: 8, bottom: 8 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e3e3de" />
        <XAxis dataKey="month" reversed tickFormatter={value => formatMonth(String(value))} tick={{ fontSize: 12 }} />
        <YAxis orientation="right" tickFormatter={formatNumber} tick={{ fontSize: 12 }} />
        <Tooltip labelFormatter={value => formatMonth(String(value))} formatter={value => [`${formatNumber(Number(value))} ج.م`, "الإيراد"]} />
        <Bar dataKey="total" fill="var(--color-primary)" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}

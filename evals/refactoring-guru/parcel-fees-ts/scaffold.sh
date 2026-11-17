#!/usr/bin/env bash
set -e
mkdir -p src/parcels
cat > src/parcels/fees.ts <<'TS'
export type DeliveryMode = "ground" | "air" | "locker";

export interface FeeAdjuster {
  adjust(feeCents: number, country: string): number;
}

const REMOTE_PREFIXES = ["IM", "ZE", "HS", "KW"];

function isDeliverable(street: string, city: string, postcode: string, country: string): boolean {
  if (street.trim() === "" || city.trim() === "") {
    return false;
  }
  if (country === "GB") {
    return postcode.replace(" ", "").length >= 5;
  }
  return postcode.length > 0;
}

function isRemote(postcode: string, country: string): boolean {
  return country === "GB" && REMOTE_PREFIXES.some((p) => postcode.toUpperCase().startsWith(p));
}

export function quoteFee(
  mode: DeliveryMode,
  weightKg: number,
  street: string,
  city: string,
  postcode: string,
  country: string,
  subtotalCents: number,
  adjusters: FeeAdjuster[] = [],
): number {
  if (!isDeliverable(street, city, postcode, country)) {
    throw new Error(`cannot deliver to ${street}, ${city}`);
  }
  const billable = Math.ceil(weightKg * 2) / 2;
  let fee: number;
  switch (mode) {
    case "ground":
      fee = 450 + 90 * billable;
      break;
    case "air":
      fee = 1400 + 300 * billable;
      break;
    case "locker":
      fee = 0;
      break;
  }
  if (mode !== "locker" && isRemote(postcode, country)) {
    fee += 800;
  }
  if (mode === "ground" && subtotalCents >= 8000) {
    fee = 0;
  }
  for (const adjuster of adjusters) {
    fee = adjuster.adjust(fee, country);
  }
  return fee;
}
TS
cat > src/parcels/labels.ts <<'TS'
import { DeliveryMode } from "./fees";

export function buildLabel(
  recipient: string,
  street: string,
  city: string,
  postcode: string,
  country: string,
  mode: DeliveryMode,
  weightKg: number,
  placedAt: Date,
): string {
  let service: string;
  let days: number;
  switch (mode) {
    case "ground":
      service = "ROAD";
      days = 4;
      break;
    case "air":
      service = "NEXT-DAY AIR";
      days = 1;
      break;
    case "locker":
      service = "LOCKER DROP";
      days = 2;
      break;
  }

  const eta = new Date(placedAt.getTime());
  let added = 0;
  while (added < days) {
    eta.setDate(eta.getDate() + 1);
    const weekday = eta.getDay();
    if (weekday !== 0 && weekday !== 6) {
      added++;
    }
  }

  const billable = Math.ceil(weightKg * 2) / 2;
  return [
    recipient.toUpperCase(),
    street,
    `${postcode} ${city}`.toUpperCase(),
    country,
    `${service}  ${billable.toFixed(1)} KG`,
    `ETA ${eta.toISOString().slice(0, 10)}`,
  ].join("\n");
}
TS
cat > src/parcels/summary.ts <<'TS'
import { quoteFee, DeliveryMode } from "./fees";

export function summarize(
  recipient: string,
  street: string,
  city: string,
  postcode: string,
  country: string,
  mode: DeliveryMode,
  weightKg: number,
  subtotalCents: number,
  placedAt: Date,
): string {
  // shipping fee for this parcel
  const fee = quoteFee(mode, weightKg, street, city, postcode, country, subtotalCents);

  // delivery estimate
  let days: number;
  switch (mode) {
    case "ground":
      days = 4;
      break;
    case "air":
      days = 1;
      break;
    case "locker":
      days = 2;
      break;
  }
  const arrival = new Date(placedAt.getTime());
  let counted = 0;
  while (counted < days) {
    arrival.setDate(arrival.getDate() + 1);
    const dow = arrival.getDay();
    if (dow !== 0 && dow !== 6) {
      counted++;
    }
  }

  // wording for the customer
  let how: string;
  switch (mode) {
    case "ground":
      how = "Delivery by road";
      break;
    case "air":
      how = "Delivery by air";
      break;
    case "locker":
      how = "Collect from a parcel locker";
      break;
  }
  const billable = Math.ceil(weightKg * 2) / 2;
  const money = (cents: number) => `EUR ${(cents / 100).toFixed(2)}`;

  // assemble the text
  const lines: string[] = [];
  lines.push(`Order for ${recipient}`);
  lines.push(`${how} to ${street}, ${postcode} ${city}, ${country}`);
  lines.push(`Billed weight: ${billable.toFixed(1)} kg`);
  lines.push(`Goods: ${money(subtotalCents)}`);
  lines.push(fee === 0 ? "Shipping: free" : `Shipping: ${money(fee)}`);
  lines.push(`Total: ${money(subtotalCents + fee)}`);
  lines.push(`Expected ${arrival.toDateString()}`);
  return lines.join("\n");
}
TS

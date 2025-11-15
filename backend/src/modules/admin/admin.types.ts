export interface SeatDefinition {
  seatId: string;
  label: string;
  type: string;
  isAisle?: boolean;
  blocked?: boolean;
}

export interface SeatRow {
  rowLabel: string;
  seats: SeatDefinition[];
}

export interface SeatLayoutPayload {
  version: number;
  rows: SeatRow[];
  updatedAt?: string;
}

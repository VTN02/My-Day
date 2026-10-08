// Common data contracts for MyDay monorepo

export type Priority = 'low' | 'medium' | 'high';

export type AccountType = 'cash' | 'card';

export type TransactionType = 'income' | 'expense';

export interface TaskDto {
  id: string;
  title: string;
  description?: string;
  category: string;
  priority: Priority;
  dueDate: string;
  dueTime?: string;
  reminder: string;
  isCompleted: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface TransactionDto {
  id: string;
  type: TransactionType;
  amountMinorUnits: number; // Integer minor currency units (e.g. cents)
  account: AccountType;
  category: string;
  description: string;
  transactionDate: string;
  createdAt: string;
  updatedAt: string;
}

export interface NoteDto {
  id: string;
  title: string;
  body: string;
  category: string;
  attachmentPath?: string;
  attachmentName?: string;
  createdAt: string;
  updatedAt: string;
}

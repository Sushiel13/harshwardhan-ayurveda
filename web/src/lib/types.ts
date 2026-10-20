export type ItemType = 'course' | 'ebook' | 'test_series';
export interface Category { id: string; name: string; slug: string; position: number }
export interface Course {
  id: string; title: string; slug: string; subtitle: string | null; description: string | null;
  thumbnail_url: string | null; category_id: string | null; instructor: string | null; language: string | null;
  price: number; mrp: number | null; is_free: boolean; is_published: boolean; is_featured: boolean;
  validity_days: number | null; created_at: string;
}
export interface Section { id: string; course_id: string; title: string; position: number }
export interface Lesson {
  id: string; course_id: string; section_id: string | null; title: string; description: string | null;
  kind: 'video' | 'pdf'; video_path: string | null; video_url: string | null; pdf_path: string | null;
  duration_minutes: number | null; is_preview: boolean; position: number;
}
export interface Note { id: string; title: string; subject: string | null; description: string | null; file_path: string; is_published: boolean; created_at: string }
export interface Ebook { id: string; title: string; author: string | null; description: string | null; cover_url: string | null; file_path: string | null; price: number; mrp: number | null; is_free: boolean; is_published: boolean }
export interface TestSeries { id: string; title: string; description: string | null; thumbnail_url: string | null; price: number; mrp: number | null; is_free: boolean; is_published: boolean; validity_days: number | null }
export interface Test { id: string; series_id: string; title: string; instructions: string | null; duration_minutes: number; marks_per_question: number; negative_marks: number; position: number; is_published: boolean }
export interface Question { id: string; test_id: string; question: string; options: string[]; correct_index: number; explanation: string | null; position: number }
export interface LiveClass { id: string; course_id: string | null; title: string; description: string | null; starts_at: string; duration_minutes: number | null; meeting_url: string | null; is_free: boolean }
export interface Profile { id: string; full_name: string | null; phone: string | null; email: string | null; role: 'student' | 'admin'; is_blocked: boolean; created_at: string }

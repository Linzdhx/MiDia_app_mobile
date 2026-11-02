export type PrioridadTarea = 'baja' | 'media' | 'alta';
export type CategoriaTarea = 'personal' | 'trabajo' | 'estudios' | 'salud' | 'otros';
export type EstadoTarea = 'pendiente' | 'completada';

export interface Tarea {
  id: string;
  titulo: string;
  descripcion: string;
  categoria: CategoriaTarea;
  prioridad: PrioridadTarea;
  fechaCreacion: string;        // ISO string
  fechaVencimiento: string | null; // ISO string o null
  estado: EstadoTarea;
}

export interface EstadisticasTareas {
  total: number;
  completadas: number;
  pendientes: number;
  porcentajeCompletadas: number;
  porCategoria: Record<CategoriaTarea, number>;
}

export const CATEGORIAS: { valor: CategoriaTarea; etiqueta: string; icono: string }[] = [
  { valor: 'personal',  etiqueta: 'Personal',  icono: 'person-outline' },
  { valor: 'trabajo',   etiqueta: 'Trabajo',   icono: 'briefcase-outline' },
  { valor: 'estudios',  etiqueta: 'Estudios',  icono: 'school-outline' },
  { valor: 'salud',     etiqueta: 'Salud',     icono: 'heart-outline' },
  { valor: 'otros',     etiqueta: 'Otros',     icono: 'ellipsis-horizontal-outline' },
];

export const PRIORIDADES: { valor: PrioridadTarea; etiqueta: string; color: string }[] = [
  { valor: 'baja',  etiqueta: 'Baja',  color: 'success' },
  { valor: 'media', etiqueta: 'Media', color: 'warning' },
  { valor: 'alta',  etiqueta: 'Alta',  color: 'danger' },
];

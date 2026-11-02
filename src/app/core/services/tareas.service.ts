import { Injectable, signal, computed } from '@angular/core';
import { Preferences } from '@capacitor/preferences';
import {
  Tarea,
  PrioridadTarea,
  CategoriaTarea,
  EstadisticasTareas,
  EstadoTarea,
} from '../models/tarea.model';

const STORAGE_KEY = 'midia_tareas';

@Injectable({ providedIn: 'root' })
export class TareasService {
  private readonly _tareas = signal<Tarea[]>([]);

  readonly tareas = this._tareas.asReadonly();

  readonly estadisticas = computed<EstadisticasTareas>(() => {
    const todas = this._tareas();
    const completadas = todas.filter(t => t.estado === 'completada').length;
    const pendientes = todas.length - completadas;

    const porCategoria = {
      personal: 0,
      trabajo: 0,
      estudios: 0,
      salud: 0,
      otros: 0,
    } as Record<CategoriaTarea, number>;

    for (const t of todas) {
      porCategoria[t.categoria] = (porCategoria[t.categoria] ?? 0) + 1;
    }

    return {
      total: todas.length,
      completadas,
      pendientes,
      porcentajeCompletadas: todas.length === 0 ? 0 : Math.round((completadas / todas.length) * 100),
      porCategoria,
    };
  });

  async inicializar(): Promise<void> {
    try {
      const { value } = await Preferences.get({ key: STORAGE_KEY });
      if (value) {
        this._tareas.set(JSON.parse(value) as Tarea[]);
      }
    } catch (err) {
      console.error('Error al cargar tareas:', err);
    }
  }

  async crearTarea(datos: Omit<Tarea, 'id' | 'fechaCreacion' | 'estado'>): Promise<Tarea> {
    const nueva: Tarea = {
      ...datos,
      id: this.generarId(),
      fechaCreacion: new Date().toISOString(),
      estado: 'pendiente',
    };
    this._tareas.update(lista => [...lista, nueva]);
    await this.persistir();
    return nueva;
  }

  async actualizarTarea(id: string, cambios: Partial<Omit<Tarea, 'id' | 'fechaCreacion'>>): Promise<void> {
    this._tareas.update(lista =>
      lista.map(t => (t.id === id ? { ...t, ...cambios } : t))
    );
    await this.persistir();
  }

  async eliminarTarea(id: string): Promise<void> {
    this._tareas.update(lista => lista.filter(t => t.id !== id));
    await this.persistir();
  }

  async toggleCompletada(id: string): Promise<void> {
    this._tareas.update(lista =>
      lista.map(t =>
        t.id === id
          ? { ...t, estado: t.estado === 'completada' ? 'pendiente' : 'completada' as EstadoTarea }
          : t
      )
    );
    await this.persistir();
  }

  async eliminarTodas(): Promise<void> {
    this._tareas.set([]);
    await this.persistir();
  }

  obtenerPorId(id: string): Tarea | undefined {
    return this._tareas().find(t => t.id === id);
  }

  obtenerFiltradas(opciones: {
    busqueda?: string;
    estado?: EstadoTarea | 'todas';
    categoria?: CategoriaTarea | 'todas';
    prioridad?: PrioridadTarea | 'todas';
  }): Tarea[] {
    let resultado = [...this._tareas()];

    if (opciones.busqueda) {
      const q = opciones.busqueda.toLowerCase();
      resultado = resultado.filter(t => t.titulo.toLowerCase().includes(q));
    }
    if (opciones.estado && opciones.estado !== 'todas') {
      resultado = resultado.filter(t => t.estado === opciones.estado);
    }
    if (opciones.categoria && opciones.categoria !== 'todas') {
      resultado = resultado.filter(t => t.categoria === opciones.categoria);
    }
    if (opciones.prioridad && opciones.prioridad !== 'todas') {
      resultado = resultado.filter(t => t.prioridad === opciones.prioridad);
    }

    // Ordenar: vencimiento más próximo primero, sin vencimiento al final
    resultado.sort((a, b) => {
      if (!a.fechaVencimiento && !b.fechaVencimiento) return 0;
      if (!a.fechaVencimiento) return 1;
      if (!b.fechaVencimiento) return -1;
      return new Date(a.fechaVencimiento).getTime() - new Date(b.fechaVencimiento).getTime();
    });

    return resultado;
  }

  obtenerTareasHoy(): Tarea[] {
    const hoy = new Date();
    const inicio = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());
    const fin = new Date(inicio.getTime() + 24 * 60 * 60 * 1000);

    return this._tareas().filter(t => {
      if (!t.fechaVencimiento) return false;
      const fecha = new Date(t.fechaVencimiento);
      return fecha >= inicio && fecha < fin;
    });
  }

  obtenerProximasAVencer(diasLimite = 3): Tarea[] {
    const ahora = new Date();
    const limite = new Date(ahora.getTime() + diasLimite * 24 * 60 * 60 * 1000);

    return this._tareas()
      .filter(t => {
        if (!t.fechaVencimiento || t.estado === 'completada') return false;
        const fecha = new Date(t.fechaVencimiento);
        return fecha >= ahora && fecha <= limite;
      })
      .sort((a, b) =>
        new Date(a.fechaVencimiento!).getTime() - new Date(b.fechaVencimiento!).getTime()
      );
  }

  private async persistir(): Promise<void> {
    try {
      await Preferences.set({
        key: STORAGE_KEY,
        value: JSON.stringify(this._tareas()),
      });
    } catch (err) {
      console.error('Error al guardar tareas:', err);
    }
  }

  private generarId(): string {
    return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
  }
}

import { Injectable, signal, effect } from '@angular/core';
import { Preferences } from '@capacitor/preferences';

export type Tema = 'claro' | 'oscuro';

const STORAGE_KEY_TEMA = 'midia_tema';
const STORAGE_KEY_NOMBRE = 'midia_nombre_usuario';

@Injectable({ providedIn: 'root' })
export class ConfiguracionService {
  readonly tema = signal<Tema>('claro');
  readonly nombreUsuario = signal<string>('');

  constructor() {
    effect(() => {
      this.aplicarTema(this.tema());
    });
  }

  async inicializar(): Promise<void> {
    try {
      const [{ value: tema }, { value: nombre }] = await Promise.all([
        Preferences.get({ key: STORAGE_KEY_TEMA }),
        Preferences.get({ key: STORAGE_KEY_NOMBRE }),
      ]);
      if (tema === 'claro' || tema === 'oscuro') {
        this.tema.set(tema);
      }
      if (nombre) {
        this.nombreUsuario.set(nombre);
      }
    } catch (err) {
      console.error('Error al cargar configuración:', err);
    }
  }

  async cambiarTema(nuevoTema: Tema): Promise<void> {
    this.tema.set(nuevoTema);
    await Preferences.set({ key: STORAGE_KEY_TEMA, value: nuevoTema });
  }

  async guardarNombreUsuario(nombre: string): Promise<void> {
    this.nombreUsuario.set(nombre);
    await Preferences.set({ key: STORAGE_KEY_NOMBRE, value: nombre });
  }

  private aplicarTema(tema: Tema): void {
    document.body.classList.toggle('dark', tema === 'oscuro');
  }
}

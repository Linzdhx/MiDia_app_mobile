import { Component, computed, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import {
  IonHeader, IonToolbar, IonTitle, IonContent, IonSearchbar, IonList,
  IonItem, IonLabel, IonIcon, IonFab, IonFabButton, IonChip,
  IonCard, IonCardContent, IonButton, IonSelect, IonSelectOption,
  IonItemSliding, IonItemOptions, IonItemOption, IonSegment, IonSegmentButton,
  AlertController, IonText
} from '@ionic/angular';
import { addIcons } from 'ionicons';
import {
  addOutline, checkmarkCircleOutline, trashOutline, createOutline,
  calendarOutline, filterOutline, listOutline, timeOutline
} from 'ionicons/icons';
import { TareasService } from '../../core/services/tareas.service';
import { Tarea, CATEGORIAS, PRIORIDADES, EstadoTarea, CategoriaTarea, PrioridadTarea } from '../../core/models/tarea.model';

@Component({
  selector: 'app-tasks',
  standalone: true,
  imports: [
    CommonModule, DatePipe, FormsModule,
    IonHeader, IonToolbar, IonTitle, IonContent, IonSearchbar, IonList,
    IonItem, IonLabel, IonIcon, IonFab, IonFabButton, IonChip,
    IonButton, IonSelect, IonSelectOption,
    IonItemSliding, IonItemOptions, IonItemOption, IonSegment, IonSegmentButton,
    IonText
  ],
  templateUrl: './tasks.page.html',
  styleUrls: ['./tasks.page.scss'],
})
export class TasksPage {
  busqueda = signal('');
  filtroEstado = signal<EstadoTarea | 'todas'>('todas');
  filtroCategoria = signal<CategoriaTarea | 'todas'>('todas');
  filtroPrioridad = signal<PrioridadTarea | 'todas'>('todas');
  mostrarFiltros = signal(false);

  readonly CATEGORIAS = CATEGORIAS;
  readonly PRIORIDADES = PRIORIDADES;

  readonly tareasFiltradas = computed(() =>
    this.tareasService.obtenerFiltradas({
      busqueda: this.busqueda(),
      estado: this.filtroEstado(),
      categoria: this.filtroCategoria(),
      prioridad: this.filtroPrioridad(),
    })
  );

  constructor(
    private tareasService: TareasService,
    private alertCtrl: AlertController,
    public router: Router,
  ) {
    addIcons({
      addOutline, checkmarkCircleOutline, trashOutline, createOutline,
      calendarOutline, filterOutline, listOutline, timeOutline
    });
  }

  onBusqueda(evento: CustomEvent): void {
    this.busqueda.set(evento.detail.value ?? '');
  }

  onFiltroEstado(valor: string): void {
    this.filtroEstado.set(valor as EstadoTarea | 'todas');
  }

  toggleFiltros(): void {
    this.mostrarFiltros.update(v => !v);
  }

  limpiarFiltros(): void {
    this.filtroEstado.set('todas');
    this.filtroCategoria.set('todas');
    this.filtroPrioridad.set('todas');
    this.busqueda.set('');
  }

  get hayFiltrosActivos(): boolean {
    return (
      this.filtroEstado() !== 'todas' ||
      this.filtroCategoria() !== 'todas' ||
      this.filtroPrioridad() !== 'todas' ||
      this.busqueda() !== ''
    );
  }

  async toggleCompletada(tarea: Tarea, sliding?: IonItemSliding): Promise<void> {
    await sliding?.close();
    await this.tareasService.toggleCompletada(tarea.id);
  }

  async eliminarTarea(tarea: Tarea, sliding?: IonItemSliding): Promise<void> {
    await sliding?.close();
    const alert = await this.alertCtrl.create({
      header: 'Eliminar tarea',
      message: `¿Eliminar "${tarea.titulo}"? Esta acción no se puede deshacer.`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        {
          text: 'Eliminar',
          role: 'destructive',
          handler: () => this.tareasService.eliminarTarea(tarea.id),
        },
      ],
    });
    await alert.present();
  }

  editarTarea(tarea: Tarea): void {
    this.router.navigate(['/tarea', tarea.id, 'editar']);
  }

  nuevaTarea(): void {
    this.router.navigate(['/tarea/nueva']);
  }

  colorPrioridad(prioridad: string): string {
    return PRIORIDADES.find(p => p.valor === prioridad)?.color ?? 'medium';
  }

  etiquetaPrioridad(prioridad: string): string {
    return PRIORIDADES.find(p => p.valor === prioridad)?.etiqueta ?? prioridad;
  }

  etiquetaCategoria(categoria: string): string {
    return CATEGORIAS.find(c => c.valor === categoria)?.etiqueta ?? categoria;
  }

  estaVencida(tarea: Tarea): boolean {
    if (!tarea.fechaVencimiento || tarea.estado === 'completada') return false;
    return new Date(tarea.fechaVencimiento) < new Date();
  }
}

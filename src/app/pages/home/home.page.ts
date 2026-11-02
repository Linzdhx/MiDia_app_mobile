import { Component, computed } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { Router } from '@angular/router';
import {
  IonHeader, IonToolbar, IonTitle, IonContent, IonCard, IonCardHeader,
  IonCardTitle, IonCardContent, IonButton, IonIcon, IonFab, IonFabButton,
  IonList, IonItem, IonLabel, IonChip, IonProgressBar
} from '@ionic/angular';
import { addIcons } from 'ionicons';
import {
  addOutline, checkmarkCircleOutline, timeOutline, calendarOutline,
  trendingUpOutline, chevronForwardOutline, alertCircleOutline
} from 'ionicons/icons';
import { TareasService } from '../../core/services/tareas.service';
import { ConfiguracionService } from '../../core/services/configuracion.service';
import { Tarea, CATEGORIAS, PRIORIDADES } from '../../core/models/tarea.model';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [
    CommonModule, DatePipe,
    IonHeader, IonToolbar, IonTitle, IonContent, IonCard, IonCardHeader,
    IonCardTitle, IonCardContent, IonButton, IonIcon, IonFab, IonFabButton,
    IonList, IonItem, IonLabel, IonChip, IonProgressBar
  ],
  templateUrl: './home.page.html',
  styleUrls: ['./home.page.scss'],
})
export class HomePage {
  readonly hoy = new Date();
  readonly estadisticas = computed(() => this.tareasService.estadisticas());
  readonly tareasHoy = computed(() => this.tareasService.obtenerTareasHoy());
  readonly proximasAVencer = computed(() => this.tareasService.obtenerProximasAVencer(3));
  readonly nombreUsuario = computed(() => this.configuracionService.nombreUsuario());
  readonly CATEGORIAS = CATEGORIAS;

  readonly diasSemana = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  readonly meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];

  constructor(
    private tareasService: TareasService,
    private configuracionService: ConfiguracionService,
    public router: Router,
  ) {
    addIcons({
      addOutline, checkmarkCircleOutline, timeOutline, calendarOutline,
      trendingUpOutline, chevronForwardOutline, alertCircleOutline
    });
  }

  get fechaFormateada(): string {
    const d = this.hoy;
    return `${this.diasSemana[d.getDay()]}, ${d.getDate()} de ${this.meses[d.getMonth()]} de ${d.getFullYear()}`;
  }

  get saludoHora(): string {
    const hora = new Date().getHours();
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  etiquetaCategoria(categoria: string): string {
    return CATEGORIAS.find(c => c.valor === categoria)?.etiqueta ?? categoria;
  }

  colorPrioridad(prioridad: string): string {
    return PRIORIDADES.find(p => p.valor === prioridad)?.color ?? 'medium';
  }

  etiquetaPrioridad(prioridad: string): string {
    return PRIORIDADES.find(p => p.valor === prioridad)?.etiqueta ?? prioridad;
  }

  async toggleCompletada(tarea: Tarea, event: Event): Promise<void> {
    event.stopPropagation();
    await this.tareasService.toggleCompletada(tarea.id);
  }

  navegarCrearTarea(): void {
    this.router.navigate(['/tarea/nueva']);
  }

  navegarTareas(): void {
    this.router.navigate(['/tareas']);
  }

  estaVencida(tarea: Tarea): boolean {
    if (!tarea.fechaVencimiento) return false;
    return new Date(tarea.fechaVencimiento) < new Date() && tarea.estado !== 'completada';
  }
}

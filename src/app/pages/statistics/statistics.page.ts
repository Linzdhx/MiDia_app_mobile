import { Component, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  IonHeader, IonToolbar, IonTitle, IonContent, IonCard, IonCardHeader,
  IonCardTitle, IonCardContent, IonIcon, IonProgressBar
} from '@ionic/angular';
import { addIcons } from 'ionicons';
import {
  checkmarkCircleOutline, timeOutline, trendingUpOutline, listOutline,
  briefcaseOutline, personOutline, schoolOutline, heartOutline,
  ellipsisHorizontalOutline
} from 'ionicons/icons';
import { TareasService } from '../../core/services/tareas.service';
import { CATEGORIAS, CategoriaTarea } from '../../core/models/tarea.model';

interface CategoriaEstadistica {
  etiqueta: string;
  icono: string;
  total: number;
  porcentaje: number;
  color: string;
}

@Component({
  selector: 'app-statistics',
  standalone: true,
  imports: [
    CommonModule,
    IonHeader, IonToolbar, IonTitle, IonContent, IonCard, IonCardHeader,
    IonCardTitle, IonCardContent, IonIcon, IonProgressBar
  ],
  templateUrl: './statistics.page.html',
  styleUrls: ['./statistics.page.scss'],
})
export class StatisticsPage {
  readonly estadisticas = computed(() => this.tareasService.estadisticas());

  readonly categoriaColores: Record<CategoriaTarea, string> = {
    personal: 'primary',
    trabajo: 'secondary',
    estudios: 'tertiary',
    salud: 'success',
    otros: 'medium',
  };

  readonly categoriaEstadisticas = computed<CategoriaEstadistica[]>(() => {
    const est = this.estadisticas();
    const total = est.total;

    return CATEGORIAS.map(cat => ({
      etiqueta: cat.etiqueta,
      icono: cat.icono,
      total: est.porCategoria[cat.valor] ?? 0,
      porcentaje: total === 0 ? 0 : Math.round(((est.porCategoria[cat.valor] ?? 0) / total) * 100),
      color: this.categoriaColores[cat.valor],
    })).filter(c => c.total > 0).sort((a, b) => b.total - a.total);
  });

  constructor(private tareasService: TareasService) {
    addIcons({
      checkmarkCircleOutline, timeOutline, trendingUpOutline, listOutline,
      briefcaseOutline, personOutline, schoolOutline, heartOutline,
      ellipsisHorizontalOutline
    });
  }
}

import { Component, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  IonHeader, IonToolbar, IonTitle, IonContent, IonList, IonItem,
  IonLabel, IonToggle, IonIcon, IonButton, IonInput, IonNote,
  IonCard, IonCardHeader, IonCardTitle, IonCardContent,
  AlertController, ToastController
} from '@ionic/angular';
import { addIcons } from 'ionicons';
import {
  moonOutline, sunnyOutline, trashOutline, informationCircleOutline,
  personOutline, saveOutline, phonePortraitOutline
} from 'ionicons/icons';
import { ConfiguracionService, Tema } from '../../core/services/configuracion.service';
import { TareasService } from '../../core/services/tareas.service';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [
    CommonModule, FormsModule,
    IonHeader, IonToolbar, IonTitle, IonContent, IonItem,
    IonLabel, IonToggle, IonIcon, IonButton, IonInput
  ],
  templateUrl: './settings.page.html',
  styleUrls: ['./settings.page.scss'],
})
export class SettingsPage {
  readonly tema = computed(() => this.configuracion.tema());
  readonly nombreUsuario = computed(() => this.configuracion.nombreUsuario());
  nombreTemp = '';

  readonly version = '1.0.0';

  constructor(
    private configuracion: ConfiguracionService,
    private tareasService: TareasService,
    private alertCtrl: AlertController,
    private toastCtrl: ToastController,
  ) {
    addIcons({
      moonOutline, sunnyOutline, trashOutline, informationCircleOutline,
      personOutline, saveOutline, phonePortraitOutline
    });
    this.nombreTemp = this.configuracion.nombreUsuario();
  }

  async toggleTema(): Promise<void> {
    const nuevoTema: Tema = this.tema() === 'claro' ? 'oscuro' : 'claro';
    await this.configuracion.cambiarTema(nuevoTema);
  }

  async guardarNombre(): Promise<void> {
    await this.configuracion.guardarNombreUsuario(this.nombreTemp.trim());
    await this.mostrarToast('Nombre guardado');
  }

  async eliminarTodas(): Promise<void> {
    const total = this.tareasService.estadisticas().total;
    const alert = await this.alertCtrl.create({
      header: 'Eliminar todas las tareas',
      message: `¿Estás seguro? Se eliminarán ${total} tarea${total !== 1 ? 's' : ''}. Esta acción no se puede deshacer.`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        {
          text: 'Eliminar todo',
          role: 'destructive',
          handler: async () => {
            await this.tareasService.eliminarTodas();
            await this.mostrarToast('Todas las tareas eliminadas', 'danger');
          },
        },
      ],
    });
    await alert.present();
  }

  private async mostrarToast(mensaje: string, color = 'success'): Promise<void> {
    const toast = await this.toastCtrl.create({
      message: mensaje,
      duration: 2000,
      color,
      position: 'bottom',
    });
    await toast.present();
  }
}

import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import {
  IonHeader, IonToolbar, IonTitle, IonContent, IonButton, IonIcon,
  IonItem, IonLabel, IonInput, IonTextarea, IonSelect, IonSelectOption,
  IonDatetime, IonDatetimeButton, IonModal, IonButtons, IonNote,
  ToastController
} from '@ionic/angular';
import { addIcons } from 'ionicons';
import { saveOutline, closeOutline, arrowBackOutline, calendarOutline } from 'ionicons/icons';
import { TareasService } from '../../core/services/tareas.service';
import { Tarea, CATEGORIAS, PRIORIDADES, CategoriaTarea, PrioridadTarea } from '../../core/models/tarea.model';

@Component({
  selector: 'app-task-form',
  standalone: true,
  imports: [
    CommonModule, ReactiveFormsModule,
    IonHeader, IonToolbar, IonTitle, IonContent, IonButton, IonIcon,
    IonItem, IonLabel, IonInput, IonTextarea, IonSelect, IonSelectOption,
    IonDatetime, IonDatetimeButton, IonModal, IonButtons, IonNote
  ],
  templateUrl: './task-form.page.html',
  styleUrls: ['./task-form.page.scss'],
})
export class TaskFormPage implements OnInit {
  form!: FormGroup;
  modoEdicion = false;
  tareaId: string | null = null;
  readonly CATEGORIAS = CATEGORIAS;
  readonly PRIORIDADES = PRIORIDADES;

  readonly hoy = new Date().toISOString();

  constructor(
    private fb: FormBuilder,
    private tareasService: TareasService,
    private router: Router,
    private route: ActivatedRoute,
    private toastCtrl: ToastController,
  ) {
    addIcons({ saveOutline, closeOutline, arrowBackOutline, calendarOutline });
  }

  ngOnInit(): void {
    this.tareaId = this.route.snapshot.paramMap.get('id');
    this.modoEdicion = !!this.tareaId;
    this.construirFormulario();

    if (this.modoEdicion && this.tareaId) {
      const tarea = this.tareasService.obtenerPorId(this.tareaId);
      if (tarea) {
        this.rellenarFormulario(tarea);
      }
    }
  }

  private construirFormulario(): void {
    this.form = this.fb.group({
      titulo: ['', [Validators.required, Validators.minLength(1), Validators.maxLength(100)]],
      descripcion: ['', [Validators.maxLength(500)]],
      categoria: ['personal' as CategoriaTarea, Validators.required],
      prioridad: ['media' as PrioridadTarea, Validators.required],
      fechaVencimiento: [null],
    });
  }

  private rellenarFormulario(tarea: Tarea): void {
    this.form.patchValue({
      titulo: tarea.titulo,
      descripcion: tarea.descripcion,
      categoria: tarea.categoria,
      prioridad: tarea.prioridad,
      fechaVencimiento: tarea.fechaVencimiento,
    });
  }

  get titulo() { return this.form.get('titulo')!; }
  get descripcion() { return this.form.get('descripcion')!; }

  async guardar(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const datos = this.form.value as {
      titulo: string;
      descripcion: string;
      categoria: CategoriaTarea;
      prioridad: PrioridadTarea;
      fechaVencimiento: string | null;
    };

    try {
      if (this.modoEdicion && this.tareaId) {
        await this.tareasService.actualizarTarea(this.tareaId, datos);
        await this.mostrarToast('Tarea actualizada correctamente', 'success');
      } else {
        await this.tareasService.crearTarea(datos);
        await this.mostrarToast('Tarea creada correctamente', 'success');
      }
      this.router.navigate(['/tareas']);
    } catch (err) {
      console.error(err);
      await this.mostrarToast('Error al guardar la tarea', 'danger');
    }
  }

  cancelar(): void {
    this.router.navigate(['/tareas']);
  }

  onFechaChange(event: CustomEvent): void {
    const val = event.detail.value;
    this.form.patchValue({ fechaVencimiento: val ?? null });
  }

  limpiarFecha(): void {
    this.form.patchValue({ fechaVencimiento: null });
  }

  private async mostrarToast(mensaje: string, color: string): Promise<void> {
    const toast = await this.toastCtrl.create({
      message: mensaje,
      duration: 2000,
      color,
      position: 'bottom',
    });
    await toast.present();
  }
}

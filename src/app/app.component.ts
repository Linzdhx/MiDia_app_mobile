import { Component, OnInit } from '@angular/core';
import { IonApp, IonRouterOutlet } from '@ionic/angular';
import { TareasService } from './core/services/tareas.service';
import { ConfiguracionService } from './core/services/configuracion.service';

@Component({
  selector: 'app-root',
  template: `
    <ion-app>
      <ion-router-outlet></ion-router-outlet>
    </ion-app>
  `,
  standalone: true,
  imports: [IonApp, IonRouterOutlet],
})
export class AppComponent implements OnInit {
  constructor(
    private tareasService: TareasService,
    private configuracionService: ConfiguracionService,
  ) {}

  async ngOnInit(): Promise<void> {
    await Promise.all([
      this.configuracionService.inicializar(),
      this.tareasService.inicializar(),
    ]);
  }
}

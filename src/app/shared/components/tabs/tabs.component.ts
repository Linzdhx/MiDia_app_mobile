import { Component } from '@angular/core';
import {
  IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel
} from '@ionic/angular';
import { addIcons } from 'ionicons';
import { homeOutline, listOutline, barChartOutline, settingsOutline } from 'ionicons/icons';

@Component({
  selector: 'app-tabs',
  standalone: true,
  imports: [IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel],
  template: `
    <ion-tabs>
      <ion-tab-bar slot="bottom" class="tab-bar-custom">
        <ion-tab-button tab="inicio" href="/inicio" id="tab-inicio">
          <ion-icon name="home-outline"></ion-icon>
          <ion-label>Inicio</ion-label>
        </ion-tab-button>
        <ion-tab-button tab="tareas" href="/tareas" id="tab-tareas">
          <ion-icon name="list-outline"></ion-icon>
          <ion-label>Mis tareas</ion-label>
        </ion-tab-button>
        <ion-tab-button tab="estadisticas" href="/estadisticas" id="tab-estadisticas">
          <ion-icon name="bar-chart-outline"></ion-icon>
          <ion-label>Estadísticas</ion-label>
        </ion-tab-button>
        <ion-tab-button tab="ajustes" href="/ajustes" id="tab-ajustes">
          <ion-icon name="settings-outline"></ion-icon>
          <ion-label>Ajustes</ion-label>
        </ion-tab-button>
      </ion-tab-bar>
    </ion-tabs>
  `,
  styles: [`
    .tab-bar-custom {
      --background: var(--ion-background-color, white);
      border-top: 1px solid var(--ion-color-light-shade);
      box-shadow: 0 -4px 16px rgba(0,0,0,0.08);
    }
  `]
})
export class TabsComponent {
  constructor() {
    addIcons({ homeOutline, listOutline, barChartOutline, settingsOutline });
  }
}

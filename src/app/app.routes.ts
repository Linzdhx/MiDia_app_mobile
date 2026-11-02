import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () => import('./shared/components/tabs/tabs.component').then(m => m.TabsComponent),
    children: [
      {
        path: 'inicio',
        loadComponent: () => import('./pages/home/home.page').then(m => m.HomePage),
      },
      {
        path: 'tareas',
        loadComponent: () => import('./pages/tasks/tasks.page').then(m => m.TasksPage),
      },
      {
        path: 'estadisticas',
        loadComponent: () => import('./pages/statistics/statistics.page').then(m => m.StatisticsPage),
      },
      {
        path: 'ajustes',
        loadComponent: () => import('./pages/settings/settings.page').then(m => m.SettingsPage),
      },
      {
        path: '',
        redirectTo: 'inicio',
        pathMatch: 'full',
      },
    ],
  },
  {
    path: 'tarea/nueva',
    loadComponent: () => import('./pages/task-form/task-form.page').then(m => m.TaskFormPage),
  },
  {
    path: 'tarea/:id/editar',
    loadComponent: () => import('./pages/task-form/task-form.page').then(m => m.TaskFormPage),
  },
];

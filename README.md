# ZeroRisco — App Flutter

App de transporte seguro em Saquarema, RJ. Desenvolvido em Flutter para Android.

## 📱 Download do APK

Acesse a aba **[Actions](../../actions)** do repositório → última build → baixe o artifact `zerorisco-debug-...`

## Stack

- **Flutter** — UI nativa Android
- **Supabase** — Autenticação
- **Socket.io** — Corridas em tempo real
- **OpenStreetMap** — Mapas sem API key
- **Backend:** https://saquadrive.onrender.com

## Funcionalidades

- Login / Cadastro com Supabase
- Mapa ao vivo com localização do motorista
- Solicitar corrida (4 tipos: ZeroFlash, ZeroRisk, ZeroPlus, ZeroGold)
- Chat em tempo real passageiro ↔ motorista
- PIN de segurança por corrida
- Botão SOS com ligação para emergências
- Painel do motorista com aceite/recusa em tempo real
- Histórico de corridas e ganhos

## Build local

```bash
flutter pub get
flutter run          # conectar celular via USB com depuração ativada
flutter build apk    # gerar APK
```

## GitHub Actions

O APK é gerado automaticamente a cada push na branch `main`.  
Veja os artifacts em **Actions → Build APK ZeroRisco**.

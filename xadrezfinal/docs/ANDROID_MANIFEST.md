# AndroidManifest.xml

No arquivo `android/app/src/main/AndroidManifest.xml`, adicione as permissões abaixo
como filhas diretas de `<manifest>` e antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Não substitua o Manifest inteiro. Preserve o `application`, `activity`, filtros de intent,
configuração do Firebase e demais atributos já criados pelo Flutter/FlutterFire.

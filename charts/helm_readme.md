# HELM Einfuehrung

"Helm is a Kubernetes-native automation technology and software package manager that simplifies deployment of applications and services. It is focused on automating day 1 tasks: deployment, installing and basic configuration management." [What is Helm](https://connect.redhat.com/en/partner-with-us/what-is-helm)

Helm ist also ein ein **templating tool** mit dem Manifests für das Deployment von Anwendungen auf Kubernetes Plattformen. Dabei wird das Template (Chart), default Werte (values.yaml), umgebungsspezifische Werte (in Form von values files) und ggf. Cluster Konfigurationswerten zu einer Anwendung verbunden.

Die detailierte Dokumentation ist auf der [Helm Docs](https://helm.sh/docs/) Seite zu finden.

## Helm CLI

Helm kann von der Kommandozeile mit dem Befehl `helm` bedient werden.

```bash
helm --help | less
```

Installation ist je nach OS unterschiedlich. Für die jeweilie Plattform siehe [Installing Helm](https://helm.sh/docs/intro/install/).

### Erstellen eines Helm Charts

```bash
helm create <templateName> 
```

Erstellt ein Template eines (lauffähigen) Charts in einm Unterverzeichnis *`<templateName>`*.

### Erstellen der Manifests des Charts

Zum Testen des Charts und zum Anzeigen der Manifests kann das Chart einfach mal gerendert werden:

```bash
helm template . --debug | less
helm template . --debug | oc apply -f -
```

### Lint'en eines Charts

Um sicherzustellen, dass das Chart korrekt formatiert ist gibt es einen "lint'er" der eingebaut ist:

```bash
helm lint <path-to-the-chart>
```

### Chart zu Helm Repo hinzufügen

Charts können in Helm Repositories zusammen gefasst werden. Charts werden dem Repo mit folgendem Command hinzugefügt

```bash
helm repo add <name-in-repo> <git-url>
```

und charts im Repo können mit diesem Befehl angezeigt werden:

```bash
helm repo list
```

### Installation, update löschen von Helm deployments

Helm Charts können mit folgenden Commands upgedated werden:

```bash
helm install <release-name> <path-to-the-chart> [--debug]  [--dry-run ] [--skip-crds] [-f | --values] [--repo] [--set key1.key11=value1,key2.key21=value2,..]

helm upgrade <release-name> <path-to-the-chart> [--debug] [--install] [similar-to-install-parameters]

helm uninstall <release-name> [--keep-history] [--dry-run]
```

### Andere interessante helm CLI commands

Die folgenden Commands sind auch immer wieder hilfreich:

```bash
helm list

helm history 

helm history  <deployment-name> 
```

Für weitere Optionen einfach `help [<comamnd>] [<sub-command>] --help` aufrufen.

# Beginn einer Helm Entwicklung

Helm/Chart Entwicklung ist wie Software Entwicklung ein iterativer Prozess mit unterscheidlichn Möglichkeiten. Für den Beginn mit Helm sollte ein möglichst einfacher Ansatz gewählt werden und von den bestehenden Manfifests ausgehend die Charts entwickelt und verfeinert werden.

## Erstellen des Chart Templates

Der erste Schritt ist das Erstellen eines Helm Charts (Template) in einem Verzeichnis. Wie z.B.

```bash
mkdir charts && cd $_
helm create myChart
```

Damit wird in Verzeichnis `charts` ein Unterverzeichnis `myChart` mit folgenden Dateien erstellt:

```bash
[hhuebler@hhuelinux2 charts]$ find .
.
./myChart
./myChart/charts
./myChart/templates
./myChart/templates/tests
./myChart/templates/tests/test-connection.yaml
./myChart/templates/_helpers.tpl
./myChart/templates/NOTES.txt
./myChart/templates/hpa.yaml
./myChart/templates/serviceaccount.yaml
./myChart/templates/service.yaml
./myChart/templates/deployment.yaml
./myChart/templates/ingress.yaml
./myChart/.helmignore
./myChart/values.yaml
./myChart/Chart.yaml
```

Wichtig dabei sind vor allem die folgenden Inhalte:

1. `./myChart/values.yaml`: Diese Datei beeinhaltet die standard Werte für die Variablen des Charts. Beim Deployment dienen die Werte dieser Datei als Defaults wenn Werte in der angegebenen Values Datei nicht definiert sind. Alternativ könne diese auch über den `--set` Parameter beim Deployment des Charts angegeben werden.
2. `./myChart/templates`: Dieses Verzeichnis beinhaltet die Templates für das Deployment. Also Yaml Dateien die ein Template der OpenShift Manifeste darstellen welche mit den entsprechenden umgebungsspezifischen Werten dann zu Manifests gerendert werden welche dann auf der OpenShift installiert werden können. Dadurch können wir die gleichen Templates in mehreren Umgebungen verwenden.
3. `./myChart/templates/_helpers.tpl`: Diese Datei ist die standard Datei für **named templates** also (Teil-) Templates die einmal definiert aber mehrfach wiederverwendet werden können. Erlaubt daher die Wiederverwendung von Code. Typisches Beispiel sind z.B. Labels die auf allen Manifests gesetzt werden sollten.
4. `./myChart/Chart.yaml`: Beinhaltet die Chart Metadaten wie Beschreibung, Chart Version, Applikationsversion etc.
5. `./myChart/.helmignore`: Eine Datei ähnlich wie die `.gitignore` Datei über die gesteuert werden kann welche Datei beim Rendern des Templates nicht berücksichtigt werden sollten. Hier sollten alle Dateien (bzw. deren Glob) aufgelistet sind die keine validen YAML Dateien darstellen.

Die anderen Dateien unter **./myChart/templates** sind Beispieldateien die mal es lohnt mal durchzusehen aber prinzipiell können diese (bist auf die **_helpers.tpl**) gelöscht werden. Damit sind

## Abrufen der bestehenden Manifests

Die bestehenden Manifests sollten zunächst mal mit `oc get <object-type>/<object-name> -o yaml | tee <file>` in die Datei `<file>` zu exportiert werden und dann nach `./myChart/templates` kopiert werden (`cp template-* /dev/shm/charts/myChart/templates`).

In einem nächsten Schritt müssen die exportierten Manifests in den Dateien `<file>` bereinigt werden indem die Einträge die den aktuellen Status im Cluster repräsentieren entfernt werden.

Damit können wir das Template schon mal rendern: `helm template . --debug | less`

Nun können wir uns überlegen welche Werte der gerenderten Manifeste sich:

- zwischen den Umgebungen auf denen deployed werden sollte ändern könnten / werden
- welche Werte sich im Laufe der Zeit ändern könnten (z.B. Kennworte, Zertifikate etc.)
- wie können wir die Flexibilität und bessere Wiederverwendbarkeit erzielen

D.h. wir müssen nun die Manifests mit Variablen flexibler gestalten.

## Einführung von Variablen

Also Zeit Variablen einzuführen und diese in den Manifests einzutragen.

Template Directive (dazu zählen auch Variablen) in Helm Charts werden durch doppelte Mengenklammern eingeschlossen angegeben also zwischen `{{` und `}}` z.B: `{{ <var-name> }}`. Dabei ist zu beachten, dass ***nur definierte Variablen*** verwendet werden sollten.  Erzwungen kann dass mit der Funtion *required* werden.

Bei der Verwendung von Variablen ist der jeweilige **Geltungsbereich (Scope)** zu beachten. Standardmäßig sind wir **top-level** oder **root** Scope.  Dieser verändert sich bei Verwendung von *Blöcken* (Schleifen, Includes etc.) automatisch und die Liste über die iteriert wird, wird das neue **root** innerhalb der Schleife.

Der **root** Scope kann unter Verwendung von **$** angegeben werden also z.B. `{{ $.Values.`<varname>` }}`.

### Standardvariablen die durch Helm gesetzt sind

Helm stelle einige Objekte standardmäßig zur Verfügung. Diese [Built-in Objects](https://helm.sh/docs/chart_template_guide/builtin_objects/). Diese sind:

- .Release
- .Values
- .Files
- .Chart
- .Capabilities
- .Template

### Erstellen und zuweisen von Variablen

Zusätzlich zu den standard Variablen können auch im Chart Variablen erstellt und diesen Werte zugewiesen werden. Variablennamen beginnen immer mit einem **$**.
Dabei ist zu unterscheiden ob es die Variable bereits gibt oder diese neu erstellt werden sollte. Um eine Variable mit dem Namen `$clusterName` zu erstellen und dieser einen Wert zuzuweisen muss folgender Code geschrieben werden: `{{ $clusterName := .Values.cluster }}`. Ist die Variable mal erstellt kann der Wert folgendermaßen geändert werden: `{{ $clusterName = .Values.k8s.clusterName }}`

### Ersetzen des Hostnamen in the Manifesten durch eine Variable

In unserem Beispiel wird sich der Hostname `tpl-d.intern.xx.yy` zwischen den Umgebungen ändern. Daher ersetzen wir diesen mal durch eine Variable. Also erstellen wir die Variable

```yaml
hostname: tpl-d.intern.xx.zz
```

 in der `values.yaml` und ersetzen alle vorkommen von `tpl-d.intern.xx.zz` in den YAML files durch `"{{ .Values.hostname }}"`

**NOTE**: Wir sehe hier, dass eine Template Directive durch doppelte Mengenklammern eingeschlossen ist also `{{` und `}}`

### Ersetzen der Resourcen

Die Resource Requests und Limits sind oft auch unterschiedlich zwischen den verschiedenen Umgebungen. Um das auch über die Chart steuern zu können führen wir eine Map für die Resourcen ein:

```yaml
resources:
  cpu:
    requests: 500m 
    limits: 2 
  memory:
    requests: 500Mi
    limits: 2Gi
```

Und tragen dann die Variablennamen in den Manifests ein: `"{{ .Values.resources.cpu.limits }}"` etc.

### Ersetzen der HTTP Header in den Probes

Die HTTP Header des **rest** Deployments setzt HTTP Header f. die Probem. Die Probes des **workspace-material** Deployments dagegen nicht. Wenn wir beide Deployments in nur einem Chart abbilden wollen müssen wir diese berücksichtigen. Daher definieren wir mal im `values.yaml` die Liste der Header für die Probes:

```yaml
probes:
  httpHeaders:
    - name: x-version
      value: "1.9"
    - name: x-authenticate-userid
      value: openshift@statistik.gv.at
    - name: x-authorize-roles
      value: OpenShift
```

Da ja wie yuvor beschrieben nur definierte Variablen verwendet werden dürfen müssen wir im Chart mal abfragen ob diese auch gesetzt sind und dann diese eintragen. Da gibts zwei Möglichkeiten dies zu implementieren.

#### Einbinden einer YAML Liste

Da die Variable hier ja eine YAML Liste dastellt, können wir diese direkt als YAML einbinden. Dafür verwenden wir [Funktionen](https://helm.sh/docs/chart_template_guide/function_list/) die Helm bereit stellt. Ausserdem sehen wir hier auch ein Beispiel wie mittles **if** Bedingungen ins Chart eingebaut werden können. Dabei beschränkt sich die Verwendung von **if** nicht nur auf die Prüfung der Existenz von Variablen sondern es kann auch auch =, >, < etc. geprüft werden. Details über die [Ablaufsteuerung](https://helm.sh/docs/chart_template_guide/control_structures/) sind in der Helm Doku zu finden.

```yaml
          {{- if .Values.probes }}
          {{- if .Values.probes.httpHeaders }}
          {{- toYaml .Values.probes.httpHeaders | nindent 10 }}
          {{- end }}
          {{- end }}
```

**Note**: Man beachte hier, dass die Helm Ausdrücke mit `{{-` beginnen. damit wird verhindert, dass für die Zeile mit der Steueranweisung eine Leerzeile ausgegeben wird. Für Details dazu siehe das Kapitel [Controlling Whitespace](https://helm.sh/docs/chart_template_guide/control_structures/#controlling-whitespace) in der Helm Dokumentation.

#### Verwendung einer loop über die Range Funktion

Auch wenn in diese Fall das Einsetzen einer YAML Liste die einfachers Implementierung ist könnte man das auch über eine Loop über die Liste machen wie im folgenden Beispiel gezeigt:

```yaml
          {{- if .Values.probes }}
          {{- if .Values.probes.httpHeaders }}
            httpHeaders:
          {{- range $key, $val := .Values.probes.httpHeaders }}
            - name: {{ $val.name }}
              value: {{ $val.value }}
          {{- end }}
          {{- end }}
          {{- end }}
```

Ein weiteres Beispiel für die Implementierung einer Lopp mit der `range` Steuerung ist folgendes:

Eintrag in der `values.yaml`:

```yaml
app:
  - name: app01
    deploymentModel: 3stage
  - name: app02
    deploymentModel: 5stage

deploymentmodels:
  3stage:
    stages:
      - stage01
      - stage02
      - stage03
  5stage:
    stages:
    - stage01
    - stage02
    - stage03
    - stage04
    - stage05
```

Code im Template:

```yaml
{{- range .Values.app }}
    {{- printf "Current app name: %s\n" .name }}
    {{ $stageList := get $.Values.deploymentmodels  .deploymentModel }}
    {{- range $stageList.stages }}
        {{- printf "Current stage : %s\n" . }}
    {{- end }}
{{- end }}
```

**Note**: Innerhalb der `range` loop ist der Scope der Variablen relativ zu `.Values.app`!

### Häufig verwendete Funktionen

Helm stellt eine Menge von Funktionen zur Verfügung die verwendet werden können. Das Kapitel [Template Functions and Pipelines](https://helm.sh/docs/chart_template_guide/functions_and_pipelines/) listet im Kapitel [Tmeplate Function list](https://helm.sh/docs/chart_template_guide/function_list/)  alle unterstützten Funktionen auf.

Darüber hinaus gibt es auch Pipeline Funktionen

- `{{ .Values.var | default <value> }}`: Setzt einen Default Wert für die Variable *var* falls diese nicht definiert ist
- `{{ .Values.var | upper }}`: Kovertiert den Wert der Variablen *var* in Grossbuchstaben
- `{{ .Values.var | lower }}`: Kovertiert den Wert der Variablen *var* in Kleinschreibung
- `{{ .Values.var | quote }}`: Stell den Wert der Variablen *var* in der Ausgabe unter Doppelhochkomma

**Note**: Diese Funtionen können auch kaskadiert werden also z.B. `{{ .Values.var | upper ' quote }}`

### Einbindung von "named templates"

Um Fragmente von Charts einzubinden und Parameter an diese zu übergeben kann folgendermassen vorgegangen werdenÖ

Beispiel eines named Templates:

```yaml
{{/*
Common labels
*/}}
{{- define "tpl.labels" -}}
{{- $top := index . 0 }}
{{- $chart := index . 1 }}
{{- $release := index . 2 }}
{{- $deploymentName := index . 3 -}}
helm.sh/chart: {{ include "tpl.chart" (list $top $chart $release) }}
{{- if $chart.AppVersion }}
app.kubernetes.io/version: {{ $chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $release.Service }}
app.kubernetes.io/name: {{ include "tpl.name" (list $top $chart $release) }}
app.kubernetes.io/instance: {{ $release.Name }}
{{- end }}
```

welches folgendermassen aufgerufen werden kann:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name }}
  labels:
    {{- include "tpl.labels" (list $ $thisChart $thisRelease .name) | nindent 4 }}
    {{- include "tpl.selectorLabels" (list $ $thisChart $thisRelease .name) | nindent 4 }}
spec:
:
:
```

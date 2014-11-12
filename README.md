何度やってもRailsが身につかない。ドットインストールの講座をやったメモを備忘録として書く。

[Ruby on Rails 4入門 (全28回) - プログラミングならドットインストール](http://dotinstall.com/lessons/basic_rails_v2)

[コード](https://github.com/tyfkda/dotinstall-rails4-tutorial)

### プロジェクト作成
`$ rails new appname`

* `--skip-bundle` でバンドルのインストールを省略して高速化

### サーバー起動
`$ rails server` または `$ rails s`

### モデル作成
`$ rails generate model Project title`

* モデル名は単数形、大文字始まり
* メンバは、後ろに`:string`や`:integer`をつけることで型を指定できる。省略すると`string`となる
* `rails g` でも可

マイグレーションファイルが生成されるので、`rake db:migrate` DBへ反映させる

### DB確認
`$ rails db`

```
sqlite> .schema
CREATE TABLE "projects" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar(255), "created_at" datetime, "updated_at" datetime);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
```

### コンソール
インタラクティブに操作できる。

`$ rails console`

* `p1 = Project.new("p1"); p1.save`
* `p2 = Project.create("p2")`


### コントローラ作成
`$ rails g controller Projects`

* コントローラの作成は複数形
* app/controllers/projects_controller.rb が生成される

### route 設定
作成したコントローラにブラウザからアクセスできるように、routeを設定する

```rb
# config/routes.rb
Rails.application.routes.draw do
  # 追加
  resources :projects

  ...
end
```

を追加する。

設定したルートの確認は `rake routes` でできる。

```bash
$ rake routes
      Prefix Verb   URI Pattern                  Controller#Action
    projects GET    /projects(.:format)          projects#index
             POST   /projects(.:format)          projects#create
 new_project GET    /projects/new(.:format)      projects#new
edit_project GET    /projects/:id/edit(.:format) projects#edit
     project GET    /projects/:id(.:format)      projects#show
             PATCH  /projects/:id(.:format)      projects#update
             PUT    /projects/:id(.:format)      projects#update
             DELETE /projects/:id(.:format)      projects#destroy
```

### 共通テンプレート
```html
// app/views/layouts/application.html.erb
<!DOCTYPE html>
<html>
<head>
  <title>Taskapp</title>
  <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
  <%= csrf_meta_tags %>
</head>
<body>

<%= yield %>

</body>
</html>
```

`<%= image_tag "logo.png" %>` でイメージタグを埋め込む。画像ファイルは app/assets/images に置く。

`<%= link_to "Home", projects_path %>` でリンクの埋め込み。

### モデルの詳細ページを作る
一覧のビューの中でリンクを指定する：

```html
// app/views/projects/index.html.erb
<%= link_to project.title, project_path(project.id) %>
```

コントローラにshowアクションを追加する：

```rb
# app/controllers/projects_controller.rb
  def show
    @project = Project.find(params[:id])
  end
```

ビューを追加する

```html
// app/views/projects/show.html.erb
<h1><%= @project.title %></h1>
```

### アイテムの新規追加を作る
```html
// app/views/projects/index.html.erb
<%= link_to "Add New", new_project_path %>
```

アクションを追加：

```rb
# app/controllers/projects_controller.rb
  def new
    @project = Project.new
  end
```

ビューを追加

```html
// app/views/projects/new.html.erb
<%= form_for @project do |f| %>
<p>
  <%= f.label :title %><br>
  <%= f.text_field :title %>
</p>

<p>
  <%= f.submit %>
</p>
```

### バリデーションの追加
入力が空の状態を防ぐなど、条件を付けられる

```rb
# app/models/project.rb
class Project < ActiveRecord::Base
  # 追加
  validates :title, presence: true
end
```

保存時、バリデーションに失敗したときに分岐させる

```rb
# app/controllers/projects_controller.rb
    if @project.save
      redirect_to project_path  # 成功した場合には一覧に飛ばす
    else
      render 'new'  # 失敗した場合にはもう一度新規追加画面に戻る
    end
```

### 要素の編集を追加
`edit` をコントローラ、ビューに追加して、編集画面を追加。

`update` で編集内容を保存。


### 編集画面を共通化する
`new` と `edit` で表示しているフォームが全く同じ形なので、パーシャルを使って共通化する。

```html
// new.html.erb,edit.html.erb
  <%= render 'form' %>
```

```html
// app/views/projects/_form.html.erb
<%= form_for ... %>
  ...
<% end %>
```

### 要素の削除

```html
<%= link_to "[Delete]", project_path(project.id), method: :delete, data: { confirm: "are you sure?" } %>
```

コントローラに`destroy` アクションを追加

```rb
# app/controllers/projects_controller.rb
  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_path
  end
```

### 「タスク」モデルの追加
タスクという、プロジェクトと１対多となるモデルを作成

`$ rails g model Task title done:boolean project:references`

`boolean` で真偽値、`references`で他のモデルへの参照。

`done`の初期値を`false`とするために、生成されたマイグレーションファイル(db/migrate/XXXX_create_tasks.rb)に `default: false` と指定してやる。

`$ rake db:migrate` でDBに反映

### ProjectモデルにTaskへの指定を追加する

```html
# app/models/project.rb
  has_many :tasks
```

ProjectがTaskと１対多であることを記述する

Taskの方は生成時に自動的に「belongs_to :project」という指定が入っているが
Projectの方は自動的には追加されないので、してやる必要がある。

### Taskへのルーティングを設定

```rb
# config/routes.rb
  resources :projects do
    # :projectsのアソシエーションとして指定、createとdestroyアクションのみ
    resources :tasks, only: [:create, :destroy]
  end
```

```bash
$ rake routes
       Prefix Verb   URI Pattern                               Controller#Action
project_tasks POST   /projects/:project_id/tasks(.:format)     tasks#create
 project_task DELETE /projects/:project_id/tasks/:id(.:format) tasks#destroy
...
```

### タスクの新規追加

```rb
# app/controllers/tasks_controller.rb
  def create
    @project = Project.find(params[:project_id])
    @task = @project.tasks.create(task_params)
    redirect_to project_path(@project.id)
  end

  ...
```

### チェックボックスの表示

```html
// app/views/projects/show.html.erb
    <%= check_box_tag '', '', task.done, {'data-id' => task.id, 'data-project_id' => task.project_id} %>
```

* あとでpostメッセージを送る時に使えるように、データフィールドにID埋め込んでおく

### toggleアクションを呼び出す
```js
// app/views/projects/show.html.erb
<script>
$(function() {
  $("input[type=checkbox]").click(function() {
    $.post('/projects/' + $(this).data('project_id') + '/tasks/' + $(this).data('id') + '/toggle');
  });
});
</script>
```

ルーティングを設定：

```rb
# config/routes.rb
  post '/projects/:project_id/tasks/:id/toggle' => 'tasks#toggle'
```

アクションでは表示内容はないので、それを指定する

```rb
# app/controllers/tasks_controller.rb
  def toggle
    render nothing: true
    ...
  end
```

.

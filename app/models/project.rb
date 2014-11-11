# -*- coding: utf-8 -*-
class Project < ActiveRecord::Base
  validates :title, presence: { message: '入力して下さい' },
                    length: { minimum: 3, message: '短すぎ！' }
end

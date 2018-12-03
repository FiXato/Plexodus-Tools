#!/usr/bin/env
# encoding: utf-8
module GoogleTakeout
  module Reference
    #FIXME: once I've moved GooglePlusProfileExport#users to User.[], I want to use user_id rather than user here.
    attr_accessor :user
  end
end
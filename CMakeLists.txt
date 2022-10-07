cmake_minimum_required(VERSION 3.22)
project(lualua)
add_library(lualua MODULE lualua.c)
set_target_properties(lualua PROPERTIES PREFIX "")

# frozen_string_literal: true

require_relative 'mention_counter'

mention_counter = MentionCounter.new('test.db',
                                     'MTA4NDQwMDI2MzUzNzg4NTI4NA.GpKyMJ.VQvkUB1LzrRgVxDc1T0spbN_t2oFfHUnxbub7Y')
mention_counter.run

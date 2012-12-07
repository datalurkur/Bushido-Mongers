module Quality
    def levels
        [
            :atrocious,
            :shoddy,
            :poor,
            :dubious,
            :substandard,
            :standard,
            :decent,
            :fine,
            :superior,
            :masterwork,
            :legendary,
        ]
    end

    def value(l)
        level    = levels.index(l)
        standard = levels.index(:standard)
        2 ** (level - standard)
    end
end

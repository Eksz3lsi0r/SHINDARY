--!strict
-- ObjectPool.lua - High-performance object pooling system for Subway Surfers
local ObjectPool = {}

-- Type definitions
export type PoolConfig = {
    initialSize: number,
    maxSize: number,
    createFunction: () -> Instance,
    resetFunction: (Instance) -> (),
    validateFunction: (Instance) -> boolean,
}

export type Pool = {
    available: { Instance },
    inUse: { Instance },
    config: PoolConfig,
    totalCreated: number,
}

-- Create a new object pool
function ObjectPool.new(config: PoolConfig): Pool
    assert(config, "Pool config is required")
    assert(config.createFunction, "createFunction is required")
    assert(config.resetFunction, "resetFunction is required")

    local pool: Pool = {
        available = {},
        inUse = {},
        config = config,
        totalCreated = 0,
    }

    -- Pre-populate pool with initial objects
    for _ = 1, config.initialSize do
        local obj = config.createFunction()
        if obj then
            obj.Parent = nil -- Keep objects hidden initially
            table.insert(pool.available, obj)
            pool.totalCreated += 1
        end
    end

    return pool
end

-- Get an object from the pool
function ObjectPool.get(pool: Pool): Instance?
    local obj = table.remove(pool.available)

    -- Create new object if pool is empty and under max size
    if not obj and pool.totalCreated < pool.config.maxSize then
        obj = pool.config.createFunction()
        if obj then
            pool.totalCreated += 1
        end
    end

    if obj then
        -- Validate object is still usable
        if pool.config.validateFunction and not pool.config.validateFunction(obj) then
            obj:Destroy()
            pool.totalCreated -= 1
            return ObjectPool.get(pool) -- Try again recursively
        end

        table.insert(pool.inUse, obj)
        pool.config.resetFunction(obj)
    end

    return obj
end

-- Return an object to the pool
function ObjectPool.returnToPool(pool: Pool, obj: Instance)
    if not obj then
        return
    end

    -- Remove from inUse list
    for i, usedObj in ipairs(pool.inUse) do
        if usedObj == obj then
            table.remove(pool.inUse, i)
            break
        end
    end

    -- Hide object and add to available pool
    obj.Parent = nil
    -- Move BasePart objects far away
    if obj:IsA("BasePart") then
        obj.CFrame = CFrame.new(0, -1000, 0)
    end
    table.insert(pool.available, obj)
end

-- Clean up expired or invalid objects
function ObjectPool.cleanup(pool: Pool)
    -- Clean available objects
    for i = #pool.available, 1, -1 do
        local obj = pool.available[i]
        if not obj or not obj.Parent then
            table.remove(pool.available, i)
            if obj then
                obj:Destroy()
            end
            pool.totalCreated -= 1
        end
    end

    -- Clean in-use objects that are no longer valid
    for i = #pool.inUse, 1, -1 do
        local obj = pool.inUse[i]
        if not obj or not obj.Parent then
            table.remove(pool.inUse, i)
            if obj then
                obj:Destroy()
            end
            pool.totalCreated -= 1
        end
    end
end

-- Get pool statistics
function ObjectPool.getStats(pool: Pool)
    return {
        available = #pool.available,
        inUse = #pool.inUse,
        totalCreated = pool.totalCreated,
        maxSize = pool.config.maxSize,
    }
end

-- Destroy all objects in pool
function ObjectPool.destroy(pool: Pool)
    -- Destroy available objects
    for _, obj in ipairs(pool.available) do
        if obj then
            obj:Destroy()
        end
    end

    -- Destroy in-use objects
    for _, obj in ipairs(pool.inUse) do
        if obj then
            obj:Destroy()
        end
    end

    -- Clear arrays
    table.clear(pool.available)
    table.clear(pool.inUse)
    pool.totalCreated = 0
end

return ObjectPool

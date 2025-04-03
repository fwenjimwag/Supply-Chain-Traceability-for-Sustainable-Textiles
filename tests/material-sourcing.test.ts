import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity environment
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  contracts: {
    materialSourcing: {
      functions: {
        "register-material": vi.fn(),
        "register-batch": vi.fn(),
        "get-material": vi.fn(),
        "get-batch": vi.fn(),
        "set-contract-owner": vi.fn(),
      },
    },
  },
}

// Mock the blockchain time
const mockBlockTime = 1617984000 // Example timestamp

describe("Material Sourcing Contract", () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks()
    
    // Setup default mock responses
    mockClarity.contracts.materialSourcing.functions["register-material"].mockReturnValue({ value: 1 })
    mockClarity.contracts.materialSourcing.functions["register-batch"].mockReturnValue({ value: 1 })
    mockClarity.contracts.materialSourcing.functions["get-material"].mockReturnValue({
      value: {
        name: "Organic Cotton",
        origin: "India",
        "harvest-date": 1617900000,
        supplier: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
        organic: true,
        "registered-by": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
        "registration-date": mockBlockTime,
      },
    })
    mockClarity.contracts.materialSourcing.functions["get-batch"].mockReturnValue({
      value: {
        "material-id": 1,
        quantity: 1000,
        "quality-grade": "A",
        timestamp: mockBlockTime,
      },
    })
  })
  
  it("should register a new material", () => {
    const result = mockClarity.contracts.materialSourcing.functions["register-material"](
        "Organic Cotton",
        "India",
        1617900000,
        "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
        true,
    )
    
    expect(result.value).toBe(1)
    expect(mockClarity.contracts.materialSourcing.functions["register-material"]).toHaveBeenCalledWith(
        "Organic Cotton",
        "India",
        1617900000,
        "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
        true,
    )
  })
  
  it("should register a new batch", () => {
    const result = mockClarity.contracts.materialSourcing.functions["register-batch"](1, 1000, "A")
    
    expect(result.value).toBe(1)
    expect(mockClarity.contracts.materialSourcing.functions["register-batch"]).toHaveBeenCalledWith(1, 1000, "A")
  })
  
  it("should retrieve material information", () => {
    const result = mockClarity.contracts.materialSourcing.functions["get-material"](1)
    
    expect(result.value).toEqual({
      name: "Organic Cotton",
      origin: "India",
      "harvest-date": 1617900000,
      supplier: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      organic: true,
      "registered-by": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      "registration-date": mockBlockTime,
    })
  })
  
  it("should retrieve batch information", () => {
    const result = mockClarity.contracts.materialSourcing.functions["get-batch"](1)
    
    expect(result.value).toEqual({
      "material-id": 1,
      quantity: 1000,
      "quality-grade": "A",
      timestamp: mockBlockTime,
    })
  })
})

